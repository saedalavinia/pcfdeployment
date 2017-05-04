#!/bin/bash

ssh-agent bash
ssh-add ~/.ssh/us-east-1.pem

ansible-playbook deployOpsman.yml
