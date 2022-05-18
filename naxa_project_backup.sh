#!/bin/bash
set -e
sudo pwd
#====================================READ USER ARGS=======================================

while getopts ":p:" opt; do
  case $opt in
    p) project_path="$OPTARG"
    ;;
    \?) echo "Invalid path -$OPTARG" >&2
    exit 1
    ;;
  esac

  case $OPTARG in
    -*) echo "Option $opt needs a valid argument"
    exit 1
    ;;
  esac
done

# -p = PATH = $project_path

#====================================READ USER ARGS=======================================


if [ ! -d "$project_path" ]; then
  while true;
    do
    echo "Please provide valid project path:"
    read project_path
    if [ -d "$project_path" ]; then
      break
    fi
  done
fi

if [ ! -d "$project_path" ];
then
    echo "No project path provided"
    echo "Please provide valid project path in -p parameter"
    echo "./backup.sh -p /projects/MyDemoProject"
    exit 1
fi


# project_path="/home/nischal/dev/OnlineDonationPlatform"

timestamp=$(date +%Y-%m-%d-%H-%M)
working_dir=`pwd`
cd $project_path
project_name=${PWD##*/}
cd $working_dir
backup_folder_name=$project_name"-BACKUP-"$timestamp
backup_dir=$working_dir/$backup_folder_name
mkdir -p $backup_dir


function backup_env() {
  env_backup=$backup_dir/Environments
  mkdir -p $env_backup

  cd $project_path
  find . -maxdepth 1 -type f -iname "*env*" -exec cp -rf '{}' "$env_backup/{}" ';'  
  cd $working_dir
}


function backup_dockerfiles() {
  mkdir -p $backup_dir/DockerSettings
  cur_dir=`pwd`
  cd $project_path
  find . -maxdepth 1 -type f -iname "*docker*" -exec cp -rf '{}' "`echo $backup_dir`/DockerSettings/{}" ';'  
  cd $cur_dir
}

function backup_mediafiles() {
  mkdir -p $backup_dir/MediaFiles
  cur_dir=`pwd`
  cd $project_path
  find . -maxdepth 1 -type d -iname "media" -exec cp -rf '{}' "`echo $backup_dir`/MediaFiles/{}" ';'  
  cd $cur_dir
}

function set_env() {
  export $(grep -v '^#' $project_path/env.txt | xargs)
}


function do_db_backup(){
  mkdir -p $backup_dir/Database
  dbname=$project_name"-"$timestamp".tar"
  db_backup_file_name=$dbname
  cd $project_path
  # db_container_name=$(echo $(docker inspect -f '{{.Name}}' $(docker-compose ps -q db) | cut -c2-))
  db_container_name=`docker-compose ps | grep 5432 | awk {'print $1'}`
  docker exec -t $db_container_name mkdir -p /var/lib/postgresql/data/db-backups
  docker exec -t $db_container_name pg_dump --format=t --blobs --verbose --no-privileges --no-owner --dbname $POSTGRES_DB --user $POSTGRES_USER --file /var/lib/postgresql/data/db-backups/$dbname
  sudo cp ./postgres_data/db-backups/$dbname $backup_dir/Database/
  cd $working_dir
}

set_env
backup_env
backup_dockerfiles
do_db_backup
backup_mediafiles
backup_tar_name=$backup_folder_name".tar.gz"
sudo chmod 744 ./$backup_folder_name
sudo chmod -R 744 ./$backup_folder_name/*
GZIP=-9 tar -zcvpf $backup_tar_name $backup_folder_name
sudo rm -r $backup_folder_name

echo "========================================="
echo "==                                     =="
echo "==         BACKUP SUCCESSFULL!         =="
echo "==                                     =="
echo "========================================="
echo "Find your backup at `pwd`"
exit 1
