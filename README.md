# Overview

Scripts to automate the conversion of an Oracle dump supplied by HMRC
into a more portable format that GDS staff can easily manipulate.

# Pre-requisites

These scripts require the use of a machine accessible via SSH which is
running a suitable version of Oracle.

An example of such a thing would be the Oracle Developer Days
VirtualBox image, which has been modified to publish an SSH public key
to the VM.

We don't currently have a snapshot like that due to concerns over
redistributing the VM. For internal GDS usage, it's probably OK, but
it's not too arduous a step to setup and we could probably automate
that a little more if required.

# Usage

Given a suitable snapshot (*.dmp), we call the script

convert.sh path/to/file.dmp

and wait for the CSV output.