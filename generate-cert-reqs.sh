#!/bin/bash

# This script creates Certificate Authority in user`s home directory and 
# generates signed certificates for Admin server and all instances of directory
# server
#
# Author:   Jan Rusnacko
# Date:     21.04.2013

# Include library
. lib.sh

generate-certs