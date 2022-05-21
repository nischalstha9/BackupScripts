#!/bin/bash
set -e
sudo pwd

#====================================READ USER ARGS=======================================
while getopts p:e:d: flag; do
  case "${flag}" in
  p) project_path=$OPTARG ;;
  e) env_file_name=$OPTARG ;;
  d) db_container_name=$OPTARG ;;
  esac
done

# -p = PATH = $project_path
# -e = PATH = $env_file_name
#====================================READ USER ARGS=======================================

project_path=$(echo "$project_path" | sed 's:/*$::')

if [ ! -d "$project_path" ]; then
  while true; do
    echo "Please provide valid project path:"
    read project_path
    if [ sudo -d "$project_path" ]; then
      break
    fi
  done
fi

if [ ! -d "$project_path" ]; then
  echo "No project path provided"
  echo "Please provide valid project path in -p parameter"
  echo "./backup.sh -p /projects/MyDemoProject"
  exit 1
fi

if [ ! -f "$project_path/$env_file_name" ]; then
  echo "Environment file not found!"
  echo "Make sure to give valid environment file name in -e parameter"
  exit 1
fi

# project_path="/home/nischal/dev/OnlineDonationPlatform"

timestamp=$(date +%Y-%m-%d-%H-%M)
working_dir=$(pwd)
cd $project_path
project_name=${PWD##*/}
cd $working_dir
backup_folder_name=$project_name"-BACKUP-"$timestamp
backup_dir=$working_dir/$backup_folder_name
mkdir -p $backup_dir

backup_log_file=$working_dir/projects.backup.log

if [ ! -f "$backup_log_file" ]; then
  touch $backup_log_file
fi

function backup_env() {
  {
    echo "Starting Environment Backup!"
    env_backup=$backup_dir/Environments
    mkdir -p $env_backup

    cd $project_path
    sudo find . -maxdepth 1 -type f -iname "*env*" -exec cp -rf '{}' "$env_backup/{}" ';'
    cd $working_dir
    echo "Environment Backup Complete!"

    log_text="$timestamp $project_name env_backup SUCCESS"
  } || {
    echo "Environment Backup Failed!"
    log_text="$timestamp $project_name env_backup FAILURE"
  }
  echo $log_text >>$backup_log_file
}

function backup_dockerfiles() {
  {
    echo "Starting Dockerfiles Backup!"
    mkdir -p $backup_dir/DockerSettings
    cur_dir=$(pwd)
    cd $project_path
    sudo find . -maxdepth 1 -type f -iname "*docker*" -exec cp -rf '{}' "$(echo $backup_dir)/DockerSettings/{}" ';'
    cd $cur_dir
    echo "Dockerfiles Backup Complete!"
    log_text="$timestamp $project_name dockerfiles_backup SUCCESS"
  } || {
    echo "Dockerfiles Backup Failed!"
    log_text="$timestamp $project_name dockerfiles_backup FAILURE"
  }
  echo $log_text >>$backup_log_file
}

function backup_mediafiles() {
  {
    echo "Starting Mediafiles Backup!"
    mkdir -p $backup_dir/MediaFiles
    cur_dir=$(pwd)
    cd $project_path
    sudo find . -maxdepth 1 -type d -iname "media" -exec cp -rf '{}' "$(echo $backup_dir)/MediaFiles/{}" ';'
    cd $cur_dir
    echo "Mediafiles Backup Complete!"
    log_text="$timestamp $project_name mediafiles_backup SUCCESS"
  } || {
    log_text="$timestamp $project_name mediafiles_backup FAILURE"
    echo "Mediafiles Backup Failed!"
  }
  echo $log_text >>$backup_log_file
}

function set_env() {
  {
    echo "Setting up Environment!"
    export $(grep -v '^#' $project_path/$env_file_name | xargs)
    echo "Environment set!"
    log_text="$timestamp $project_name env_setup SUCCESS"
  } || {
    log_text="$timestamp $project_name env_setup FAILURE"
    echo "Environment Setup Failed!"
    exit 1

  }
  echo $log_text >>$backup_log_file
}

function do_db_backup() {
  echo "Starting Database Backup!"
  mkdir -p $backup_dir/Database
  dbname=$project_name"-"$timestamp".tar"
  db_backup_file_name=$dbname
  DATABASE_NAME=$DATABASE_NAME$POSTGRES_DB$SQL_DATABASE
  DATABASE_USER=$DATABASE_USER$POSTGRES_USER$SQL_USER
  {
    set -e
    cd $project_path
    # db_container_name=$(echo $(docker inspect -f '{{.Name}}' $(docker-compose ps -q db) | cut -c2-))

    if [ ! $db_container_name ]; then
      echo "NO Database Container name defined. Define it in -d parameter."
      echo "Finding Database Container ......."
      db_container_name=$(docker-compose ps | grep 5432 | awk {'print $1'})
      echo "Database container resolved: $db_container_name"
    fi

    # db_container_name=psql_naxa

    echo "Backing up Database..."
    docker exec -t $db_container_name mkdir -p /var/lib/postgresql/data/db-backups
    docker exec -t $db_container_name pg_dump --format=t --blobs --no-privileges --no-owner --dbname $DATABASE_NAME --user $DATABASE_USER --file /var/lib/postgresql/data/db-backups/$dbname

    postgresdatafoldername=$(echo $(find . -maxdepth 1 -type d -iname "postgres*"))
    postgresdatafoldername=$(echo "$postgresdatafoldername" | sed 's:./::')

    sudo cp $project_path/$postgresdatafoldername/db-backups/$dbname $backup_dir/Database/
    sudo rm -r $project_path/$postgresdatafoldername/db-backups
    cd $working_dir
    echo "Database Backup Complete!"
    log_text="$timestamp $project_name database_backup SUCCESS"
  } || {
    echo "Database backup failed!!"
    log_text="$timestamp $project_name database_backup FAILURE"
    # pg_dump --format=t --blobs --verbose --no-privileges --no-owner --dbname $POSTGRES_DB --user $POSTGRES_USER --file /var/lib/postgresql/data/db-backups/$dbname
    # sudo cp ./postgres_data/db-backups/$dbname $backup_dir/Database/
  }
  echo $log_text >>$backup_log_file

}

set_env
backup_env
backup_dockerfiles
do_db_backup
backup_mediafiles
backup_tar_name=$backup_folder_name".tar.gz"
sudo chmod 777 ./$backup_folder_name
sudo chmod -R 777 ./$backup_folder_name/*
sudo chown $USER:$USER ./$backup_folder_name
sudo chown -R $USER:$USER ./$backup_folder_name/*
# GZIP=-9 tar -zcvpf $backup_tar_name $backup_folder_name

s3path="s3://naxa-developers/backups/projects-backups/$project_name/$backup_tar_name"

echo "Creating TAR file on AWS..."
sudo tar cpz $backup_folder_name | gzip | aws s3 cp - $s3path
echo "TAR file creation complete!"
echo "Cleaning up...."
sudo rm -r $backup_folder_name

echo "========================================="
echo "==                                     =="
echo "==         BACKUP SUCCESSFULL!         =="
echo "==                                     =="
echo "========================================="
echo "Find your backup at $s3path"

exit 0
