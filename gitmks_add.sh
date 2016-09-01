#!/bin/bash

GIT_DIR='.'
LOCAL_PATH=''
PROJECT=''

usage()
{
   echo "      add        [MKS project] <local path> initializes a git/MKS repository at the local location"
}

MKSUSER="`git config --get mks.user`"
retval=$?
if [ $retval != 0 ]; then
   echo "mks.user is not set in git config" >&2
   exit 255
fi

if [ "$1" == usage ];then
   usage
   exit 255
fi

if [ $# -lt 2 ]; then
   echo "You Must specify a MKS project" >&2
   exit 256
else
   LOCAL_PATH=$3
fi

cd $LOCAL_PATH

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

PROJECT=$2
si viewproject --project $PROJECT --no --quiet --user $MKSUSER &> /dev/null
retval=$?

if [ $retval != 0 ]; then
   echo "You must enter a valid MKS project" >&2
   exit 64
fi

cd $GIT_DIR
GIT_DIR="`pwd`"

git rev-parse --git-dir 2> /dev/null
retval=$?

if [ $retval == 0 ]; then
   echo "A git directory has already been created in this location" >&2
   exit 128
fi

git init

mkdir .git/mks_remote
cd .git/mks_remote

git init
git checkout -b MKS

si createsandbox -P $PROJECT --yes --user $MKSUSER
git add -A
git commit -m 'Initial Import from MKS'

cd $GIT_DIR
git remote add shared .git/mks_remote
git remote update

git branch --track shared/MKS

