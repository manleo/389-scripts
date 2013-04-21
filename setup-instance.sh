#!/bin/bash

# This script creates new instance of Directory Server with default values. 
# To use custom settings, edit variables below.
#
# Author:   Jan Rusnacko
# Date:     21.4.2013

INSTANCE="dstet"
SUFFIX="o=my.com"
BENAME="exampleDB"
USER="nobody"
GROUP="nobody"
ROOTDN="cn=Directory Manager"
ROOTDNPW="Secret123"
PORT=389
FQDN=`hostname -f`

setup-instance()
{
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
    #else
       # rm $LOGFILE
        #rm $TMPFILE
    fi

    return $RESULT
}

setup-instance