#!/bin/bash

SCRIPTSLOC="`dirname $0`"

git remote update
git rebase shared/MKS

exit $?

