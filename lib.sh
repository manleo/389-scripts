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


generate-certs()
{
    CERTDIR="$HOME/certificates"
    CA="$HOME/ca"
    NOISE=$CA/noise.txt
    PWDFILE=$CA/pwdfile.txt

    if [ ! -d $CERTDIR ]; then 
        mkdir $CERTDIR
    fi

    # Populate CA directory
    rm -rf $CA
    if [ ! -d $CA ]; then 
        mkdir $CA
    fi
    echo "Secret123" > $PWDFILE
    dd if=/dev/urandom bs=100 count=1 of=$NOISE

    # Create CA database
    cd $CA
    echo "certutil -d . -N -f $PWDFILE"
    certutil -d . -N -f $PWDFILE

    # Generate CA cert
    echo "generate CA"
    echo "y\n\ny\n" | certutil -S -d . -n "CA Cert" -s "cn=CA Cert" -2 -x -t "CT,," -m 1000 -v 120 -k rsa -g 1024 -f $PWDFILE -z $NOISE

    # Export CA Cert
    certutil -d . -L -n "CA Cert" -a > $CERTDIR/cacert.asc

    # Create admin server request
    cd /etc/dirsrv/admin-serv
    certutil -d . -R -s "cn=admin" -a -o "$CERTDIR/admin.req" -k rsa -g 1024 -f $PWDFILE -z $NOISE

    # Create requests for dirsrv instances
    for INST in /etc/dirsrv/slapd-*; do
        if [ ! `echo $INST | grep ".removed"` ]; then
            cd $INST
            NAME=`echo $INST | sed "s/.*slapd-\(.*\)/\1/"`
            certutil -d . -R -s "cn=$NAME" -a -o "$CERTDIR/$NAME.req" -k rsa -g 1024 -f $PWDFILE -z $NOISE
        fi
    done

    # Sign requests and create certificates
    cd $CA
    certutil -C -d . -c "CA Cert" -a -i "$CERTDIR/admin.req" -o "$CERTDIR/admin.asc" -m 1001 -v 120 -f $PWDFILE    
    i=1002
    for INST in "$CERTDIR/*.req"; do
        NAME=`echo $INST | sed "s/.*\/\(.*\).req/\1/"`
        certutil -C -d . -c "CA Cert" -a -i "$CERTDIR/$NAME.req" -o "$CERTDIR/$NAME.asc" -m $i -v 120 -f $PWDFILE
        i=$((i+1))
    done
}
