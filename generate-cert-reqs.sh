#!/bin/bash

DIRSRV="slapd-dstet"

CERTDIR="~/certdir"
NOISE=$CERTDIR/noise.txt
PWDFILE=$CERTDIR/pwdfile.txt

mkdir $CERTDIR
echo "Secret123" > $PWDFILE
dd if=/dev/urandom bs=100 of=$NOISE

# Create CA database
cd $CERTDIR
certutil -d . -N -f $PWDFILE

# Generate CA cert
echo "y\n\ny\n" | certutil -S -d . -n "CA Cert" -s "cn=CA Cert" -2 -x -t "CT,," -m 1000 -v 120 -k rsa -g 1024 -f $PWDFILE -z $NOISE

# Export CA Cert
certutil -d . -L -n "CA Cert" -a > ~/cacert.asc

# Create dirsrv request
cd /etc/dirsrv/$DIRSRV
certutil -d . -N -f $PWDFILE
certutil -d . -R -s "cn=$DIRSRV" -a -o "~/dirsrv.req" -k rsa -g 1024 -f $PWDFILE -z $NOISE

# Create admin server request
cd /etc/dirsrv/admin-serv
certutil -d . -N -f $PWDFILE
certutil -d . -R -s "cn=admin" -a -o "~/admin.req" -k rsa -g 1024 -f $PWDFILE -z $NOISE

# Sign requests and create certificates
cd $CERTDIR
certutil -C -d . -c "CA Cert" -a -i "~/admin.req" -o "~/admin.asc" -m 1001 -v 120 -f $PWDFILE
certutil -C -d . -c "CA Cert" -a -i "~/dirsrv.req" -o "~/dirsrv.asc" -m 1002 -v 120 -f $PWDFILE