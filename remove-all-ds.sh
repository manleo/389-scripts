#!/bin/bash

# This script removes all instances of directory server in /etc/dirsrv using
# remove-ds.pl script. Names of instances are pulled from /etc/dirsrv/* and 
# those that end with "removed" are ignored
#
# Author:   Jan Rusnacko
# Date:     21.04.2013

# Include library
. `dirname $0`/lib.sh

remove-all-ds