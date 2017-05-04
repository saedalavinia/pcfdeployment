#!/bin/bash

cd /home/saedalav/Documents/PCF

source /home/saedalav/.bashrc
#eval 'ssh-agent'
#ssh-add /home/saedalav/.ssh/us-east-1.pem

echo "Starting Ansible Commands"
echo "-------------------------"

ansible-playbook deployAll.yml -vvv

echo "Ansible Command Completed"
echo "-------------------------"

echo "Sending Email:"
echo "-------------------------"

cat /home/saedalav/Desktop/output.txt | mail -s "Ansible Output Logs" saedalav@gmail.com


echo "Job Finished Successfully"

