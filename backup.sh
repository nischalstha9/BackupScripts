#!/bin/bash
set -e
#====================================READ USER ARGS=======================================

while getopts ":p:" opt; do
  case $opt in
    p) project_path="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
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




working_dir=`pwd`
cd $project_path
project_name=${PWD##*/}
cd $working_dir
backup_dir=$working_dir/$project_name"_BACKUP_$(date +%Y-%m-%d)"
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
  export $(grep -v '^#' $project_path/.env | xargs)
}

function do_db_backup(){
  mkdir -p $backup_dir/Database
  dbname="`echo $project_name`_$(date +%Y-%m-%d).tar"
  backup_file_name=$backup_dir/Database/$dbname
  pg_dump --format=t --blobs --verbose --no-privileges --no-owner --password --username $DATABASE_USER --dbname $DATABASE_NAME --host $DATABASE_HOST --port $DATABASE_PORT --file $backup_file_name
}

set_env
backup_env
backup_dockerfiles
do_db_backup
backup_mediafiles

echo "BACKUP SUCCESSFULL!"
echo "Find your backup at `pwd`"

exit 1