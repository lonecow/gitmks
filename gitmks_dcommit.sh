#!/bin/bash

BaseCleanup()
{
   git branch -D temp_staged &> /dev/null
   cd $CURRENTDIR
   $SCRIPTSLOC/gitmks.sh fetch &> /dev/null
   $SCRIPTSLOC/gitmks.sh rebase &> /dev/null
   git remote prune shared
}

CleanupFailure()
{
   git reset HEAD~ --hard &> /dev/null
   git clean -dxf
   BaseCleanup
}

CleanupSucess()
{
   BaseCleanup
}


ORIGIFS=$IFS
MKSUSER="`git config --get mks.user`"
retval=$?
if [ $retval != 0 ]; then
   echo "mks.user is not set in git config" >&2
   exit 255
fi

JIRAHOST="`git config --get jira.host`"
retval=$?
if [ $retval != 0 ]; then
   echo "jira.host is not set in git config" >&2
   exit 255
fi
PTCHOST="`git config --get mks.host`"
retval=$?
if [ $retval != 0 ]; then
   echo "mks.host is not set in git config" >&2
   exit 255
fi

FOUND="FALSE"
while [ "$FOUND" == "FALSE" ]; do
   echo "Please Enter your windows password"
   read -s PASSWORD
   if [ -n "$PASSWORD" ]; then
      FOUND="TRUE"
   fi
   if [ "$FOUND" == "FALSE" ]; then
      echo "[$PASSWORD] is an invalid entry try again. or hit ctrl+c to cancel"
   fi
done

# set $IFS to end-of-line
IFS=`echo -en "\n\b"`

SCRIPTSLOC="`dirname $0`"

ISSUE=""

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

for patch in `git rev-list HEAD..temp_staged --reverse`; do
   echo -e "\n\n***************************************************************************"
   echo "Commit Message:"
   echo "   `git log --pretty="format:%B" $patch~1..$patch`"
   echo "Files Changed:"
   for file in `git diff --name-only $patch~1..$patch`; do
      echo "   $file"
   done
   echo -e "***************************************************************************\n"

   OLD_ISSUE=$ISSUE
   FOUND="FALSE"
   while [ "$FOUND" == "FALSE" ]; do
      if [ -z "$OLD_ISSUE" ]; then
         echo "Please Enter the Issue Number"
      else
         echo "Please Enter the Issue Number or hit ctrl+c to cancel [$OLD_ISSUE]"
      fi
      read ISSUE
      if [ -n "$ISSUE" ]; then
         FOUND="TRUE"
      elif [ -n "$OLD_ISSUE" ]; then
         FOUND="TRUE"
         ISSUE=$OLD_ISSUE
      fi
      if [ "$FOUND" == "FALSE" ]; then
         echo "[$ISSUE] is an invalid entry try again. or hit ctrl+c to cancel"
      fi
   done

   for file in `git diff --name-only --diff-filter "CRTUXB" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh "$file" .mksignore
      if [ "$?" == 0 ]; then
         echo "Trying to dcommit one of the unsupported types [CRTUXB]. Canceling dcommit" >&2
         BaseCleanup
         exit 255
      fi
   done

   #make sure that all members are not locked and not frozen
   for file in `git diff --name-only --diff-filter "DM" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh "$file" .mksignore
      if [ "$?" == 0 ]; then
         # is it frozen
         si memberinfo "$file" | grep "This member is frozen"
         frozen=$?
         #is it locked
         lockinfo="`si memberinfo \"$file\" | grep \"Locked By:\"`"
         #is it locked by me
         si memberinfo "$file" | grep "Locked By:" | grep ${MKSUSER}
         locked_by_me=$?
         echo "$file" | grep ".pj$"
         # check it it is a project

         if [ -n "$lockinfo" -a "$locked_by_me" != "0" ]; then
            echo "One of the files is already locked. Canceling dcommit" >&2
            BaseCleanup
            exit 255
         fi
         if [ "$frozen" = "0" ]; then
            echo "One of the files is frozen. Canceling dcommit" >&2
            BaseCleanup
            exit 255
         fi
      fi
   done

   git cherry-pick $patch &> /dev/null
   retval=$?
   if [ $retval != 0 ]; then
      echo "Could not cherry pick commit. Canceling dcommit" >&2
      BaseCleanup
      exit 255
   fi

   patch="`git log --pretty="format:%H" HEAD~..HEAD`"

   COMMITMESSAGE="`git log --pretty="format:%B" $patch~1..$patch`"
   SUMMARY="`echo $COMMITMESSAGE | cut -c1-250`"

   PACKAGE=`python.exe $SCRIPTSLOC/CreateChangePackage.py --summary "$SUMMARY" --description "$COMMITMESSAGE" --ptc_host $PTCHOST $JIRAHOST $USERNAME $PASSWORD $ISSUE`
   retval=$?
   if [ $retval != 0 ]; then
      echo "Could not create a change package for issue [$ISSUE]" >&2
      echo "si createcp returned [$PACKAGE]" >&2
      CleanupFailure
      exit 255
   fi

   # lock all of the files
   for file in `git diff --name-only --diff-filter "M" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh "$file" .mksignore
      if [ "$?" == 0 ]; then
         lockinfo="`si memberinfo \"$file\" | grep \"Locked By:\"`"
         si memberinfo "$file" | grep "Locked By:" | grep ${MKSUSER}
         locked_by_me=$?
         if [ -z "$lockinfo" -a "$locked_by_me" != "0" ]; then
            si lock --no --cpid $PACKAGE "$file"
            retval=$?
            if [ $retval != 0 ]; then
               echo "Could not Lock all files. Canceling dcommit" >&2
               CleanupFailure
               exit 255
            fi
         fi
      fi
   done

   #we are going to add files that were newly added
   for file in `git diff --name-only --diff-filter "A" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh "$file" .mksignore
      if [ "$?" == 0 ]; then
         CURRENT_DIR=`pwd`
         cd "`dirname "$file"`"
         si add --createSubprojects --nocloseCP --nounexpand --cpid $PACKAGE --description "$COMMITMESSAGE" --yes "`basename "$file"`"
         retval=$?
         cd $CURRENT_DIR
         if [ $retval != 0 ]; then
            echo "Could not add all files. Canceling dcommit" >&2
            CleanupFailure
            exit 255
         fi
      fi
   done

   #we are going to drop files that were removed
   #drop members
   for file in `git diff --name-only --diff-filter "D" $patch~1..$patch | grep -v .pj$`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh "$file" .mksignore
      if [ "$?" == 0 ]; then
         si drop --noconfirm --nocloseCP --cpid $PACKAGE "$file"
         retval=$?
         if [ $retval != 0 ]; then
            echo "Could not drop all files. Canceling dcommit" >&2
            CleanupFailure
            exit 255
         fi
      fi
   done

   #drop projects
   for file in `git diff --name-only --diff-filter "D" $patch~1..$patch | grep .pj$ | awk -F "/" '{print NF "|" $0}' | sort -n -r | awk -F "|" '{print $2}'`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh "$file" .mksignore
      if [ "$?" == 0 ]; then
         si drop --noconfirm --nocloseCP --cpid $PACKAGE "$file"
         retval=$?
         if [ $retval != 0 ]; then
            echo "Could not drop all files. Canceling dcommit" >&2
            CleanupFailure
            exit 255
         fi
      fi
   done

   # check in all of the files
   for file in `git diff --name-only --diff-filter "M" $patch~1..$patch`; do
      #is file ignored?
      $SCRIPTSLOC/gitmks_ignore.sh "$file" .mksignore
      if [ "$?" == 0 ]; then
         si ci --unlock --nounexpand --nocloseCP --confirmbranchVariant -Y --cpid $PACKAGE --description "$COMMITMESSAGE" --update "$file"
         retval=$?
         if [ $retval != 0 ]; then
            echo "Could not check in all files. Canceling dcommit" >&2
            CleanupFailure
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

CleanupSucess

IFS=$ORIGIFS

exit 0

