#!/bin/bash

usage()
{
   echo "      info        Displays the MKS repository information"
}

if [ "$1" == usage ];then
   usage
   exit 255
fi

#get the location of the .git diretory
CURRENTDIR="`pwd`"
GITDIR="`git rev-parse --git-dir 2> /dev/null`"
retval=$?

if [ $retval != 0 -o ! -d $GITDIR/mks_remote ]; then
   echo "You are not it an mks associated git directory" >&2
   exit 128
fi

cd $GITDIR/mks_remote

si sandboxinfo

