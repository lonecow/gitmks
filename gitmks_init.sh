#!/bin/bash

GIT_DIR='.'
PROJECT=''

usage()
{
   echo "      init        [MKS project] <local path> initializes a git/MKS repository at the local location"
}

if [ "$1" == usage ];then
   usage
   exit 255
fi

if [ $# -lt 2 ]; then
   echo "You Must specify a MKS project" >&2
   exit 256
elif [ ! -d $3 ]; then
   mkdir -p $3
   GIT_DIR=$3
else
   GIT_DIR=$3
fi

echo -e "\n      Please enter your mks user name:\n"

read USERNAME

PROJECT=$2
si viewproject --project $PROJECT --no --quiet --user $USER> /dev/null
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

git config --add mks.user $USER

mkdir .git/mks_remote
cd .git/mks_remote

git init
git co -b MKS

si createsandbox -P $PROJECT --yes --user $USER
git add -A
git ci -m 'Initial Import from MKS'

cd $GIT_DIR
git remote add shared .git/mks_remote
git remote update

