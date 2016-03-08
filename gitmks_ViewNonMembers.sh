#!/bin/bash

GIT_DIR='.'
LOCAL_PATH=''
PROJECT=''

usage()
{
   echo "      viewnonmembers        lists all non members in si project"
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
   file_name=`basename $GITDIR/mks_remote/$line`
   dir_name=`dirname $GITDIR/mks_remote/$line`
   cd $dir_name
   si viewnonmembers --user $USER -S $file_name --exclude=dir:.git
   cd - > /dev/null
done

