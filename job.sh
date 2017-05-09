#!/bin/bash

email=saedalav@gmail.com
output_path=/home/ec2-user/output.txt
root_directory=/home/ec2-user/pcfdeployment

cd $root_directory

source /home/ec2-user/.bashrc

echo "Pulling the latest updates from Git"
echo "-----------------------------------"

git checkout master
git pull origin master


echo "Starting Ansible Commands"
echo "-------------------------"

ansible-playbook deployAll.yml -vvv


echo "Ansible Command Completed"
echo "-------------------------"

echo "Sending Email:"
echo "-------------------------"

cat $output_path | mail -s "Ansible Output Logs" $email


echo "Job Finished Successfully"

