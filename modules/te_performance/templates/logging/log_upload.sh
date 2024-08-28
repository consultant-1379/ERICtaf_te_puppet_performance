#!/bin/bash
# Log transfer and report generate script
# ssh-keyscan(1) -H ftp.lmera.ericsson.se >> ~/.ssh/known_hosts is required 

echo $USER

logs_dir=$1
folder=$2

archive="<%= te_logs %>/$folder.tar"

ftp_log_dir="<%= ftp_log_storage %>/$folder.tar"

unzip="tar -xvf <%= ftp_log_storage %>/$folder.tar -C <%= ftp_log_storage %>/"

remove_ftp_archive="rm -f $ftp_log_dir"

#generate allure
sudo <%= allure_cli_path %>/allure generate -v <%= allure_version %> $1/$2 -o $1/$2

#zip log folder
sudo tar -cvf $archive -C $logs_dir $folder

#copy to ftp
sudo sshpass -p <%= log_storage_user_pw %> scp $archive <%= log_storage_user %>@<%= ftp_host %>:<%= ftp_log_storage %>

#remove local archive
sudo rm -f $archive

#unzip on ftp
sudo sshpass -p <%= log_storage_user_pw %> ssh <%= log_storage_user %>@<%= ftp_host %> $unzip

#remove ftp archive
sudo sshpass -p <%= log_storage_user_pw %> ssh <%= log_storage_user %>@<%= ftp_host %> $remove_ftp_archive