#!/bin/bash

GIT_DIR='.'
PROJECT=''

usage()
{
   echo "      init        <local path> initializes a git/MKS repository at the local location"
}

if [ "$1" == usage ];then
   usage
   exit 255
fi

if [ $# -lt 1 ]; then
   echo "You Must specify a local path" >&2
   exit 256
elif [ ! -d $2 ]; then
   mkdir -p $2
   GIT_DIR=$2
else
   GIT_DIR=$2
fi

echo -e "\n      Please enter your mks user name:\n"

read USERNAME

cd $GIT_DIR
GIT_DIR="`pwd`"

git rev-parse --git-dir 2> /dev/null
retval=$?

if [ $retval == 0 ]; then
   echo "A git directory has already been created in this location" >&2
   exit 128
fi

git init

git config --add mks.user $USERNAME

mkdir .git/mks_remote
cd .git/mks_remote

git init
git checkout -b MKS

cd $GIT_DIR
git remote add shared .git/mks_remote
git remote update
git br master --track shared/MKS

