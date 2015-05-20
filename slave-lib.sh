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

    # Import CA cert
    echo "Import CA"
    /usr/bin/certutil -A -d . -n "CA certificate" -t "CT,," -i /etc/openldap/cacerts/cacert.pem -f $PWDFILE

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
       #### Works on localhost in Ansible
    cd $OpenSSL_CA #utils/pki/CA
    openssl req -in csr/${server-region}-ds.csr -noout -text
    openssl ca -config openssl.cnf -policy policy_anything -days 3650 -in csr/${server-region}-ds-admin.csr -out certs/${server-region}-ds-admin.crt
    openssl ca -config openssl.cnf -policy policy_anything -days 3650 -in csr/${server-region}-ds.csr -out certs/${server-region}-ds.crt
       #### Here we will import certs with certutil on new 389 server
    /usr/bin/certutil -A -d /etc/dirsrv/slapd-{{inventory_hostname_short}} -n "server-cert" -t "u,u,u" -i /etc/pki/CA/certs/server-cert.crt -f /root/pwdfile
    /usr/bin/certutil -A -d /etc/dirsrv/admin-serv -n "admin-cert" -t "u,u,u" -i /etc/pki/CA/certs/admin-cert.crt -f /root/pwdfile
}

add_users()
{
    HOST=${1:-"localhost"}
    PORT=${2:-389}
    ROOTDN=${3:-"cn=directory manager"}
    ROOTDNPW=${4:-"Secret123"}
    TEMPLATE_NAME=${5:-"tuser"}
    SUFFIX=${6:-"ou=people,dc=example,dc=com"}
    NUMBER=${7:-100}

    for i in $(seq 1 $NUMBER); do
        ldapmodify -h $HOST -p $PORT -D "$ROOTDN" -w "$ROOTDNPW" -a <<EOF
dn: uid=$TEMPLATE_NAME$i,$SUFFIX
objectClass: top
objectClass: inetOrgPerson
objectClass: person
cn: $TEMPLATE_NAME$i
sn: $TEMPLATE_NAME$i
uid: $TEMPLATE_NAME$i
EOF
    done
}
