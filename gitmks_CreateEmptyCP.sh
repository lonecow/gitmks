#!/bin/bash


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

CURRENTDIR="`pwd`"
GITDIR="`git rev-parse --git-dir 2> /dev/null`"
retval=$?

if [ $retval != 0 -o ! -d $GITDIR/mks_remote ]; then
   echo "You are not it an mks associated git directory" >&2
   exit 128
fi

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

COMMITMESSAGE="${@:2}"
SUMMARY="`echo $COMMITMESSAGE | cut -c1-250`"

PACKAGE=`python.exe $SCRIPTSLOC/CreateChangePackage.py --summary "$SUMMARY" --description "$COMMITMESSAGE" --ptc_host $PTCHOST $JIRAHOST $USERNAME $PASSWORD $ISSUE`
retval=$?
if [ $retval != 0 ]; then
   echo "Could not create a change package for issue [$ISSUE]" >&2
   echo "si createcp returned [$PACKAGE]" >&2
   exit 255
fi

IFS=$ORIGIFS

exit 0

