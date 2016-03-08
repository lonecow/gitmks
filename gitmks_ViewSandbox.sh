#!/bin/bash

GIT_DIR='.'
LOCAL_PATH=''
PROJECT=''

usage()
{
   echo "      viewsandbox        opens a mks gui for each sanbox in the git project"
}

if [ "$1" == usage ];then
   usage
   exit 255
fi

#we want to make sure that a git repository is located at the given location
GITDIR="`git rev-parse --git-dir 2> /dev/null`"
retval=$?

if [ $retval != 0 ]; then
   echo "The local path given is not a git repository" >&2
   exit 128
fi

#TODO what if LOCAL path is absolute? What if its relative?
if [ ! -d $GITDIR/mks_remote/$LOCAL_PATH ]; then
   echo "You are not it an mks associated git directory" >&2
   exit 128
fi

USER="`git config --get mks.user`"

for line in `cat $GITDIR/mks_projects`; do
   si viewsandbox --user $USER -g -S $GITDIR/mks_remote/$line
done

