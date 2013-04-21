#!/bin/bash

# This script removes all instances of directory server in /etc/dirsrv using
# remove-ds.pl script. Names of instances are pulled from /etc/dirsrv/* and 
# those that end with "removed" are ignored
#
# Author: 	Jan Rusnacko
# Date: 	21.04.2013

remove-all-ds()
{
	LOGFILE=`mktemp`.log
	RESULT=0

	# Remove all instances of directory server
    for INST in /etc/dirsrv/slapd-*; do
        if [ ! `echo $INST | grep ".removed"` ]; then
            sudo remove-ds.pl -i $INST &>$LOGFILE
            if [ $? != 0 ]; then
                RESULT=1
            fi
        fi
    done

    if [ $RESULT != 0 ];then
       	echo "Error: logfile in $LOGFILE"
    else
       	rm $LOGFILE
    fi

    return $RESULT
}

remove-all-ds