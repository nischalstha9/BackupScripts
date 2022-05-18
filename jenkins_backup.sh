cd /home/nischal/jenkins_backup/
FOLDER_NAME=JENKINS-$(date +"%d-%m-%Y")
mkdir $FOLDER_NAME
rsync -av --progress /var/lib/jenkins/* /home/nischal/jenkins_backup/$FOLDER_NAME --exclude workspace --exclude .npm
tar -cvzf $FOLDER_NAME.tar.gz $FOLDER_NAME
rm -rf $FOLDER_NAME
find /home/nischal/jenkins_backup/* -type f -ctime +7 -exec rm -rf {} \;
