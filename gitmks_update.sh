#!/bin/bash

#get the location of the .git diretory
CURRENTDIR="`pwd`"
GITDIR="`git rev-parse --git-dir 2> /dev/null`"
retval=$?

if [ $retval != 0 -o ! -d $GITDIR/mks_remote ]; then
   echo "You are not it an mks associated git directory" >&2
   exit 128
fi

USER="`git config --get mks.user`"

for line in `cat $GITDIR/mks_projects`; do
   echo "si resync -S $GITDIR/mks_remote/${line} --yes --quiet --user $USER"
   si resync -S $GITDIR/mks_remote/${line} --yes --quiet --user $USER
done

cd $GITDIR/mks_remote
git add -A &> /dev/null
git ci -m "Resync"

cd $CURRENTDIR
git remote update shared &> /dev/null

exit 0

