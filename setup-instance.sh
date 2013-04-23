#!/bin/bash

# This script creates new instance of Directory Server with default values. 
# To use custom settings, edit variables below.
#
# Author:   Jan Rusnacko
# Date:     21.4.2013

# Include library
. `dirname $0`/lib.sh

INSTANCE="dstet"
SUFFIX="o=my.com"
BENAME="exampleDB"
USER="nobody"
GROUP="nobody"
ROOTDN="cn=Directory Manager"
ROOTDNPW="Secret123"
PORT=389
FQDN=`hostname -f`

setup-instance $INSTANCE "$SUFFIX" $BENAME $USER $GROUP "$ROOTDN" "$ROOTDNPW" \
    $PORT $FQDN