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

FOUND="FALSE"
while [ "$FOUND" == "FALSE" ]; do
   echo "Please Enter the Issue Number"
   read ISSUE
   if [ -n "$ISSUE" ]; then
      FOUND="TRUE"
   fi
   if [ "$FOUND" == "FALSE" ]; then
      echo "[$ISSUE] is an invalid entry try again. or hit ctrl+c to cancel"
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

   COMMITMESSAGE="`git log --pretty="format:%B" $patch~1..$patch`"

   PACKAGE=`si createcp --issueId=$ISSUE --description "$COMMITMESSAGE" --summary "$COMMITMESSAGE" 2>&1`
   if [ $retval != 0 ]; then
      echo "Could not create a change package for issue [$ISSUE]" >&2
      echo "si createcp returned [$PACKAGE]" >&2
      git br -D temp_staged &> /dev/null
      git reset HEAD~ --hard &> /dev/null
      cd $CURRENTDIR
      $SCRIPTSLOC/gitmks.sh rebase &> /dev/null
      git remote prune shared
      exit 255
   fi
   PACKAGE=`echo $PACKAGE | awk '{print $5}'`

   #make sure that all members are not locked
   for file in `git diff --name-only --diff-filter "DM" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh $file .mksignore
      if [ "$?" == 0 ]; then
         lockinfo="`si memberinfo \"$file\" | grep \"Locked By:\"`"
         si memberinfo "$file" | grep "Locked By:" | grep rbitel
         locked_by_me=$?
         if [ -n "$lockinfo" -a "$locked_by_me" != "0" ]; then
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
   for file in `git diff --name-only --diff-filter "M" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh $file .mksignore
      if [ "$?" == 0 ]; then
         lockinfo="`si memberinfo \"$file\" | grep \"Locked By:\"`"
         si memberinfo "$file" | grep "Locked By:" | grep rbitel
         locked_by_me=$?
         if [ -z "$lockinfo" -a "$locked_by_me" != "0" ]; then
            si lock --no --cpid $PACKAGE $file
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
      fi
   done

   #we are going to add files that were newly added
   for file in `git diff --name-only --diff-filter "A" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh $file .mksignore
      if [ "$?" == 0 ]; then
         CURRENT_DIR=`pwd`
         cd `dirname $file`
         si add --createSubprojects --nocloseCP --nounexpand --cpid $PACKAGE --description "$COMMITMESSAGE" `basename $file`
         retval=$?
         cd $CURRENT_DIR
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
   #drop members
   for file in `git diff --name-only --diff-filter "D" $patch~1..$patch | grep -v .pj$`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh $file .mksignore
      if [ "$?" == 0 ]; then
         si drop --noconfirm --nocloseCP --cpid $PACKAGE $file
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

   #drop projects
   for file in `git diff --name-only --diff-filter "D" $patch~1..$patch | grep .pj$ | awk -F "/" '{print NF "|" $0}' | sort -n -r | awk -F "|" '{print $2}'`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh $file .mksignore
      if [ "$?" == 0 ]; then
         si drop --noconfirm --nocloseCP --cpid $PACKAGE $file
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
         si ci --unlock --nounexpand --nocloseCP --confirmbranchVariant -Y --cpid $PACKAGE --description "$COMMITMESSAGE" --update $file
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

   si closecp $PACKAGE

   # we are no longer amending changes, we are going to resync between each commit 
   cd $CURRENTDIR
   $SCRIPTSLOC/gitmks.sh fetch
   cd $GITDIR/mks_remote
done

git br -D temp_staged
cd $CURRENTDIR
$SCRIPTSLOC/gitmks.sh rebase
git remote prune shared

IFS=$ORIGIFS

exit 0

