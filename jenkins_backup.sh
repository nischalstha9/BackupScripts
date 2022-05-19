#!/bin/bash

set -e

mkdir -p /home/nischal/jenkins_backup
cd /home/nischal/jenkins_backup/
find /home/nischal/jenkins_backup/* -type f -ctime +3 -exec rm -rf {} \;
FOLDER_NAME=JENKINS-$(date +"%d-%m-%Y")
mkdir $FOLDER_NAME
rsync -av --progress /var/lib/jenkins/* /home/nischal/jenkins_backup/$FOLDER_NAME --exclude workspace --exclude .npm
TARNAME="$FOLDER_NAME.tar.gz"
tar -cvzf $TARNAME $FOLDER_NAME
rm -rf $FOLDER_NAME
chmod 644 $TARNAME
aws s3 cp $TARNAME s3://naxa-developers/Jenkins_backup/$TARNAME
