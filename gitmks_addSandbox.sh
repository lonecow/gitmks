#!/bin/bash

usage()
{
   echo "      add         [MKS project] <local folder> initializes a git/MKS repository at the local location"
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


if [ $# -lt 2 ]; then
   echo "You Must specify a MKS project" >&2
   exit 256
elif [ $# -lt 3 ]; then
   PROJECT_DIR="."
elif [ ! -d $GITDIR/mks_remote/$3 ]; then
   mkdir -p $GITDIR/mks_remote/$3
   PROJECT_DIR=$3
else
   PROJECT_DIR=$3
fi

USER="`git config --get mks.user`"

PROJECT=$2
si viewproject --project $PROJECT --no --quiet --user $USER &> /dev/null
retval=$?

if [ $retval != 0 ]; then
   echo "You must enter a valid MKS project" >&2
   exit 64
fi

cd $GITDIR/mks_remote

if [ -e $PROJECT_DIR/$PROJECT ]; then
   echo "This project is already added to Git project" >&2
   exit 32
fi

cd $PROJECT_DIR

echo `pwd`

si createsandbox -P $PROJECT --yes --user $USER

git add -A
git ci -m "Initial Import from MKS for $PROJECT_DIR/`basename $PROJECT`"

cd $CURRENTDIR
git remote update

echo "$PROJECT_DIR/`basename $PROJECT`" >> $GITDIR/mks_projects
echo "echo \"$PROJECT_DIR/`basename $PROJECT`\" >> $GITDIR/mks_projects"

