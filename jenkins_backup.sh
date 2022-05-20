#!/bin/bash

set -e

mkdir -p /home/nischal/jenkins_backup
cd /home/nischal/jenkins_backup/
find /home/nischal/jenkins_backup/* -type f -ctime +3 -exec rm -rf {} \;
FOLDER_NAME=JENKINS-$(date +"%d-%m-%Y")
mkdir -p $FOLDER_NAME
rsync -av --progress /var/lib/jenkins/* /home/nischal/jenkins_backup/$FOLDER_NAME --exclude workspace --exclude .npm
sudo chmod -R 644 $FOLDER_NAME
sudo chmod -R 644 $FOLDER_NAME/*
TARNAME="$FOLDER_NAME.tar.gz"
s3path="s3://naxa-developers/backups/jenkins-backups/$TARNAME"
sudo tar cpz $FOLDER_NAME | gzip | aws s3 cp - $s3path
sudo rm -rf $FOLDER_NAME
