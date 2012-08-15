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
SCRIPTSLOC="`dirname $0`"

if [ $retval != 0 -o ! -d $GITDIR/mks_remote ]; then
   echo "You are not it an mks associated git directory" >&2
   exit 128
fi

cd $GITDIR/..

echo "Cleaning..."
for entry in `git ls-files --others -i --exclude-standard --directory`; do
   #is file ignored?
   $SCRIPTSLOC/gitmks_ignore.sh $entry .mksignore
   if [ "$?" == 0 ]; then
      rm -rf $entry
   fi
done

cd $GITDIR/mks_remote
for entry in `git ls-files --others -i --exclude-standard --directory`; do
   DIRNAME=`dirname $entry`
   if [ ! -d $DIRNAME ]; then
      mkdir -p $DIRNAME
   fi
   cp -r $entry ../../$DIRNAME
done

echo "Done"

IFS=$ORIGIFS
