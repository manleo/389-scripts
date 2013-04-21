#!/bin/bash

# This library contains useful functions for working with 389 Directory Server.
#
# Author:   Jan Rusnacko
# Date:     21.4.2013


# Creates new instance of Directory Server with default values
#
# Usage: setup-instance $INSTANCE $SUFFIX $BENAME $USER $GROUP $ROOTDN $ROOTDNPW
#           $FQDN $PORT 
setup-instance()
{
    INSTANCE=$1 ; shift
    SUFFIX=$1 ; shift
    BENAME=$1 ; shift
    USER=$1 ; shift
    GROUP=$1 ; shift
    ROOTDN=$1 ; shift
    ROOTDNPW=$1 ; shift
    PORT=$1 ; shift
    FQDN=$1 ; shift

    LOGFILE=`mktemp`.log
    TMPFILE=`mktemp`.inf
    RESULT=0

    cat >  $TMPFILE <<EOF
[General] 
FullMachineName=$FQDN
SuiteSpotUserID=$USER
SuiteSpotGroup=$GROUP

[slapd] 
ServerPort=$PORT
ServerIdentifier=$INSTANCE
Suffix=$SUFFIX
RootDN=$ROOTDN
RootDNPwd=$ROOTDNPW
ds_bename=$BENAME
SlapdConfigForMC= Yes 
UseExistingMC= 0 
AddSampleEntries= No
EOF

    sudo setup-ds.pl -s -f $TMPFILE &>$LOGFILE
    if [ $? != 0 ]; then
            RESULT=1
    fi

    if [ $RESULT != 0 ];then
        echo "Error: logfile in $LOGFILE, input in $TMPFILE"
    else
        rm $LOGFILE
        rm $TMPFILE
    fi

    return $RESULT
}

# Removes all instances of directory server in /etc/dirsrv using remove-ds.pl 
# script. Names of instances are pulled from /etc/dirsrv/* and those that end
# with "removed" are ignored
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