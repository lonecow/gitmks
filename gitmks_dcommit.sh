#!/bin/bash

ORIGIFS=$IFS

# set $IFS to end-of-line
IFS=`echo -en "\n\b"`

SCRIPTSLOC="`dirname $0`"

$SCRIPTSLOC/gitmks.sh fetch
$SCRIPTSLOC/gitmks.sh rebase
retval=$?

if [ "$retval" != "0" ]; then
   exit $retval
fi

#get the location of the .git diretory
CURRENTDIR="`pwd`"
GITDIR="`git rev-parse --git-dir 2> /dev/null`"
retval=$?

if [ $retval != 0 -o ! -d $GITDIR/mks_remote ]; then
   echo "You are not it an mks associated git directory" >&2
   exit 128
fi

git push shared HEAD:temp_staged -q

cd $GITDIR/mks_remote

echo -e "\n\n______________________________________________________________________"
echo -e "      You Must Choose a Change package"
echo -e "\n      Current Open Change Packages:\n"
si viewcps
echo -e "______________________________________________________________________\n\n"

CPLIST="`si viewcps | awk '{print $1}'`"

FOUND="FALSE"
while [ "$FOUND" == "FALSE" ]; do
   echo "Please Enter the package Number:"
   read PACKAGE

   si viewcp $PACKAGE &> /dev/null
   retval=$?

   if [ $retval -eq 0 ]; then
      for element in $CPLIST; do
         if [ "$PACKAGE" == "$element" ]; then
            FOUND="TRUE"
         fi
      done
   fi

   if [ "$FOUND" == "FALSE" ]; then
      echo "[$PACKAGE] is an invalid entry try again. or hit ctrl+c to cancel"
   fi
done

for patch in `git rev-list HEAD..temp_staged --reverse`; do
   for file in `git diff --name-only --diff-filter "CRTUXB" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh $file .mksignore
      if [ "$?" == 0 ]; then
         echo "Trying to dcommit one of the unsupported types [CRTUXB]. Canceling dcommit" >&2
         git br -D temp_staged &> /dev/null
         cd $CURRENTDIR
         $SCRIPTSLOC/gitmks.sh rebase &> /dev/null
         git remote prune shared
         exit 255
      fi
   done

   git cherry-pick $patch &> /dev/null
   retval=$?
   if [ $retval != 0 ]; then
      echo "Could not cherry pick commit. Canceling dcommit" >&2
      git br -D temp_staged &> /dev/null
      cd $CURRENTDIR
      $SCRIPTSLOC/gitmks.sh rebase &> /dev/null
      git remote prune shared
      exit 255
   fi

   patch="`git log --pretty="format:%H" HEAD~..HEAD`"

   COMMITMESSAGE="`git log --pretty="format:%s" $patch~1..$patch`"

   #make sure that all members are not locked
   for file in `git diff --name-only --diff-filter "DM" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh $file .mksignore
      if [ "$?" == 0 ]; then
         LOCKINFO="`si viewlocks $file`"
         si viewlocks $file | grep rbitel
         LOCKED_BY_ME=$?
         if [ -n "$LOCKINFO" -a "$LOCKED_BY_ME" != "0" ]; then
            echo "One of the files is already locked. Canceling dcommit" >&2
            git br -D temp_staged &> /dev/null
            git reset HEAD~ --hard &> /dev/null
            cd $CURRENTDIR
            $SCRIPTSLOC/gitmks.sh rebase &> /dev/null
            git remote prune shared
            exit 255
         fi
      fi
   done

   # lock all of the files
   for file in `git diff --name-only --diff-filter "DM" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh $file .mksignore
      if [ "$?" == 0 ]; then
         si lock --cpid $PACKAGE $file
         retval=$?
         if [ $retval != 0 ]; then
            echo "Could not Lock all files. Canceling dcommit" >&2
            git br -D temp_staged &> /dev/null
            git reset HEAD~ --hard &> /dev/null
            cd $CURRENTDIR
            $SCRIPTSLOC/gitmks.sh rebase &> /dev/null
            git remote prune shared
            exit 255
         fi
      fi
   done

   #we are going to add files that were newly added
   for file in `git diff --name-only --diff-filter "A" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh $file .mksignore
      if [ "$?" == 0 ]; then
         si add --nocloseCP --cpid $PACKAGE --description "$COMMITMESSAGE" $file
         retval=$?
         if [ $retval != 0 ]; then
            echo "Could not add all files. Canceling dcommit" >&2
            git br -D temp_staged &> /dev/null
            git reset HEAD~ --hard &> /dev/null
            cd $CURRENTDIR
            $SCRIPTSLOC/gitmks.sh rebase &> /dev/null
            git remote prune shared
            exit 255
         fi
      fi
   done

   #we are going to drop files that were removed
   for file in `git diff --name-only --diff-filter "D" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh $file .mksignore
      if [ "$?" == 0 ]; then
         si drop --nocloseCP --cpid $PACKAGE --description "$COMMITMESSAGE" $file
         retval=$?
         if [ $retval != 0 ]; then
            echo "Could not drop all files. Canceling dcommit" >&2
            git br -D temp_staged &> /dev/null
            git reset HEAD~ --hard &> /dev/null
            cd $CURRENTDIR
            $SCRIPTSLOC/gitmks.sh rebase &> /dev/null
            git remote prune shared
            exit 255
         fi
      fi
   done

   # check in all of the files
   for file in `git diff --name-only --diff-filter "M" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh $file .mksignore
      if [ "$?" == 0 ]; then
         si ci --unlock --nocloseCP --cpid $PACKAGE --description "$COMMITMESSAGE" --update $file
         retval=$?
         if [ $retval != 0 ]; then
            echo "Could not check in all files. Canceling dcommit" >&2
            git br -D temp_staged &> /dev/null
            git reset HEAD~ --hard &> /dev/null
            cd $CURRENTDIR
            $SCRIPTSLOC/gitmks.sh rebase &> /dev/null
            git remote prune shared
            exit 255
         fi
      fi
   done

   git ci -a --amend --reuse-message $patch
done

git br -D temp_staged
cd $CURRENTDIR
$SCRIPTSLOC/gitmks.sh rebase
git remote prune shared

IFS=$ORIGIFS

exit 0

