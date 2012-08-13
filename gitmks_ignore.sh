#!/bin/bash

ORIGIFS=$IFS

# set $IFS to end-of-line
IFS=`echo -en "\n\b"`

FILE="$1"

if [ ! -e $2 ]; then
   exit 0
fi

for line in `cat $2`; do
   FILE="`echo $FILE | grep -v \"^$line\"`"
done

if [ -z "$FILE" ]; then
   RETVAL=255
else
   RETVAL=0
fi

IFS=$ORIGIFS

exit $RETVAL

