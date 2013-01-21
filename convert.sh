#!/bin/bash

# script to automate the load and export to CSV of an oracle dump
# This script assumes:
# * you have the vagrant published key available locally in your .ssh directory
# * You have the Oracle VirtualBox image running locally
# ** ssh port-forwarding is configured for host port 2022 -> guest port 22.

set -e

# FIXME: Parameterise the script more, rather than defining variables like this.
SSH_PORT=2022
ORACLE_HOST=127.0.0.1

REMOTE_MACHINE="oracle@${ORACLE_HOST}"

# FIXME: Allow the key to be parameterised, and publish the key to the server?
SSH_ARGS="-i ${HOME}/.ssh/vagrant -p $SSH_PORT"

if [ -z "$1" ]; then
  echo "Usage: $0 dmp_file [TABLESPACE]"
  exit 1
fi

if [ -z "$2" ]; then
  TABLESPACE="MSSDBO"
else
  TABLESPACE="$2"
fi

DMP_FILE="$1"
DMP_FILE_NAME=`basename $DMP_FILE`

# FIXME: We could template and generate the create-${TABLESPACE}.sql file using a here doc?

# Copy utility scripts
rsync -Pae "ssh $SSH_ARGS" "create-${TABLESPACE}.sql" data-fixes.sql dump2csv.sql export.sql $REMOTE_MACHINE:~/
# Copy database dump
rsync -Pae "ssh $SSH_ARGS" $DMP_FILE $REMOTE_MACHINE:~/

# Did we use a compressed file or not? Trade Tariff database is 1.4GB uncompressed .dmp file, or 128MB compressed.
if [ $(file $DMP_FILE | grep -c gzip) == "1" ]; then
  ssh $SSH_ARGS $REMOTE_MACHINE "gunzip $DMP_FILE_NAME"
  DMP_FILE_NAME=${DMP_FILE_NAME%.*} # Strip the last part of the filename; presumably .gz
fi

if [ $(file $DMP_FILE | grep -c bzip2) == "1" ]; then
  ssh $SSH_ARGS $REMOTE_MACHINE "bunzip2 $DMP_FILE_NAME"
  DMP_FILE_NAME=${DMP_FILE_NAME%.*} # Strip the last part of the filename; presumably .bz2
fi

echo "dmp file name: ${DMP_FILE_NAME}"

# create the tablespace, user, grants, and directory object
ssh $SSH_ARGS $REMOTE_MACHINE "sqlplus / as sysdba @create-${TABLESPACE}.sql"

# Create the schema
# import the Oracle .dmp file
ssh $SSH_ARGS $REMOTE_MACHINE "imp $TABLESPACE/$TABLESPACE file=$DMP_FILE_NAME full=y rows=n"

# Alter the schema as necessary, clean up garbage data, etc.
# eg some character encoding jiggery pokery is easiest to handle by just making the columns wider
# and assume Oracle does the Right Thing with characterset conversion.
ssh $SSH_ARGS $REMOTE_MACHINE "sqlplus $TABLESPACE/$TABLESPACE @data-fixes.sql"

# Import the data
ssh $SSH_ARGS $REMOTE_MACHINE "imp $TABLESPACE/$TABLESPACE file=$DMP_FILE_NAME full=y data_only=y"

# Create the PL/SQL procedure to export tables to CSV
ssh $SSH_ARGS $REMOTE_MACHINE "sqlplus $TABLESPACE/$TABLESPACE @dump2csv.sql"
# Ensure that the target directory is created.
ssh $SSH_ARGS $REMOTE_MACHINE "mkdir /tmp/import_data"

# Run the script to export all the tables
ssh $SSH_ARGS $REMOTE_MACHINE "sqlplus $TABLESPACE/$TABLESPACE @export.sql"

# Zip up the export
ssh $SSH_ARGS $REMOTE_MACHINE "cd /tmp; tar cjvf import_data.tar.bz2 import_data"

# Copy the export
rsync -Pae "ssh $SSH_ARGS" $REMOTE_MACHINE:/tmp/import_data.tar.bz2 ./$(date +%Y-%m-%dT%H%M%S)-import_data.tar.bz2
