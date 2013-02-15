#!/bin/bash
usage()
{
echo "$0 [options]"

echo "
   Options:"
   $SCRIPTSLOC/gitmks_init.sh usage
   $SCRIPTSLOC/gitmks_info.sh usage
   $SCRIPTSLOC/gitmks_clean.sh usage
   $SCRIPTSLOC/gitmks_addSandbox.sh usage
echo "      update      updates the mks remote for the given repository
      fetch       updates the mks remote for the given repository
      rebase      rebases the mks remote to the currently checked out branch"
}

SCRIPTSLOC="`dirname $0`"

if [ "$1" == "update" -o "$1" == "fetch" ]; then
   $SCRIPTSLOC/gitmks_update.sh
   exit $?
elif [ "$1" == "rebase" ]; then
   $SCRIPTSLOC/gitmks_rebase.sh
   exit $?
elif [ "$1" == "dcommit" ]; then
   $SCRIPTSLOC/gitmks_dcommit.sh
   exit $?
elif [ "$1" == "init" ]; then
   $SCRIPTSLOC/gitmks_init.sh $@
   exit $?
elif [ "$1" == "info" ]; then
   $SCRIPTSLOC/gitmks_info.sh $@
   exit $?
elif [ "$1" == "clean" ]; then
   $SCRIPTSLOC/gitmks_clean.sh $@
   exit $?
elif [ "$1" == "add" ]; then
   $SCRIPTSLOC/gitmks_addSandbox.sh $@
   exit $?
else
   usage $@
   exit 255
fi
