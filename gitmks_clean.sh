#!/bin/bash

usage()
{
   echo "      clean        cleans all ignored files out of working directory"
}

ORIGIFS=$IFS

# set $IFS to end-of-line
IFS=`echo -en "\n\b"`

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

cd $GITDIR/..

echo "Cleaning..."
for entry in `cat .gitignore`; do
   rm -rf $entry

   if [ -e $GITDIR/mks_remote/$entry ]; then
      cp -r $GITDIR/mks_remote/$entry $entry
   fi
done

echo "Done"

IFS=$ORIGIFS
