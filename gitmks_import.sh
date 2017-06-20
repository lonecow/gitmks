#!/bin/bash

#get the location of the .git diretory
CURRENTDIR="`pwd`"
GITDIR="`git rev-parse --git-dir 2> /dev/null`"
retval=$?

if [ $retval != 0 -o ! -d $GITDIR/mks_remote ]; then
   echo "You are not it an mks associated git directory" >&2
   exit 128
fi

MKSUSER="`git config --get mks.user`"
retval=$?
if [ $retval != 0 ]; then
   echo "mks.user is not set in git config" >&2
   exit 255
fi

HOSTNAME="`git config --get mks.host`"
retval=$?
if [ $retval != 0 ]; then
   echo "mks.host is not set in git config" >&2
   exit 255
fi

SERVER=`echo $HOSTNAME | awk -F ":" '{print $1}'`
PORT=`echo $HOSTNAME | awk -F ":" '{print $2}'`

for line in `cat $GITDIR/mks_projects`; do
   echo "si importsandbox --hostname $SERVER --port $PORT $GITDIR/mks_remote/${line}"
   si importsandbox --hostname $SERVER --port $PORT --user $MKSUSER $GITDIR/mks_remote/${line}
done

cd $CURRENTDIR
git remote update shared &> /dev/null

exit 0

