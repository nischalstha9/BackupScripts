#!/bin/bash

set -e
timestamp=$(date +%Y-%m-%d-%H-%M)

backup_log_file="./jenkins.backup.log"

if [ ! -f "$backup_log_file" ]; then
    touch $backup_log_file
fi

{
    mkdir -p /home/nischal/jenkins_backup
    cd /home/nischal/jenkins_backup/
    find /home/nischal/jenkins_backup/* -type f -ctime +3 -exec rm -rf {} \;
    FOLDER_NAME=JENKINS-$(date +"%d-%m-%Y")
    mkdir -p $FOLDER_NAME
    rsync -av --progress /var/lib/jenkins/* /home/nischal/jenkins_backup/$FOLDER_NAME --exclude workspace --exclude .npm
    sudo chmod -R 666 $FOLDER_NAME
    sudo chmod -R 666 $FOLDER_NAME/*
    TARNAME="$FOLDER_NAME.tar.gz"
    s3path="s3://naxa-developers/backups/jenkins-backups/$TARNAME"
    sudo tar cpz $FOLDER_NAME | gzip | aws s3 cp - $s3path
    sudo rm -rf $FOLDER_NAME
    log_text="$timestamp jenkins_backup SUCCESS"
} || {
    log_text="$timestamp jenkins_backup FAILURE"
}
echo $log_text >>$backup_log_file
