# Automation of Pivotal Cloud Foundry deployment to AWS 
- Author: Saed Alavinia
- Email: saedalav@gmail.com
- Github: github.com/saedalav 

This project fully automates the deployment of Pivotal Cloud Foundry to AWS. The following dependencies are required: 
- Ansible 2.0+
- Python 2.7+
- Python Boto Library
- PCF UAAC (User Accound and Authentication CLI) 
- Pivotal Cloud Foundry Elastic Runtime 1.10.x Binaries. See here: https://network.pivotal.io/products/elastic-runtime
- Additionally, you must have AWS_SECRET_ACCESS_ID and AWS_ACCESS_KEY environment variables set and a key for accessing EC2 instances in the desired region must be available.   
- Note that your AWS Account must allow more than 20 EC2 VMs to be started in your region. 

This is tested in CentOS7/RHEL7 Environment. A vagrant box & AMI are created, in which only the two environment variables need to be set and a new/existing key from AWS EC2 needs to be placed in ~/.ssh folder. 
Note: It's best to run this from a control machine hosted in AWS as there is a significant performance increase. 


# Runnning the Playbook

There are 7 Ansible roles in the project: 
- cloudformation
- opsmanagerdeploy
- directorConfig
- modifyserver ** (-> This was necessary to work around a API Bug and I recognize that it's not safe to do this) 
- directorInstall
- elasticruntimeupload
- elastricruntimeconfig

Before you can run the roles separately or by using the deployAll.yml playbook, the var/main.yml in each role must be set to your preferred values. 

Once all variables are set, the entire process can be automated by:

```sh
$ ansible-playbook deployAll.yml
```
 

Alternatively, you can run a crontab job at a specific time. For example: 

```sh
$ crontab -e
0 5 * * * path/to/job.sh > /path/to/an/output.txt
```

Which starts the job.sh at 5 AM (A good time as the deployment takes about 4 hours). If you running the job.sh, you must also run the variable containing the root project path, output.txt path, and an email address to which, the logs can be emailed. 


Each role is fully independant from it's previous role and can be run separately if needed. Here is a quick description of ech role: 


###### cloudformation: 
Creates and run the PCF CloudFormation Stack. 
 -- PCF Cloud formation stack starts another stack which can either be the default stack or a S3 stack of your choice. For testing, I created my own stack to save on costs by shrinking the database size. This can be set in the variable section. You also need to set ssl certificate. I used AWS Certificate Manager.
 
###### opsmanagerdeploy: 
Uses a PCF AMI to deploy PCF Operations Manager and then configures internal security in it. 
This section requires a username and password for Operations Manager for which Ansible Vault must be ideally used. However for demonstration purposes, I pass the password as text

###### directoryconfig: 
This role uses Operations Manager API to configure Ops Manager Director (with the help of CF UAAC to generate API token). Keep in mind that there is a bug in their API that does not allow seeting the external database and blobstore location using the API. I created another role that SSH to the server and manually replaces the Installation.yml file. I do understand that this is not safe and should not be used. However, for the demonstration purposes (and to obtain a fully automated pipeline) I chose to do this. 

###### modifyserver
This role SSH to the Ops Manager server to manually modify the Installation.yml due to a bug in their API

###### directorInstall
This role initiates installation of Director and deployment of BOSH, followed by pasuing and polling to see if it is successfully installed. 

###### elasticruntimeupload
This role uploads the image for elasticruntime (appx 6.1 GB) and neeeds to be available in the path. This is very important to be performed by an AWS machine (AMI prepared, but currently private as I can't share PCF's contents). 

###### elastricruntimeconfig
This role check to see if elasticruntime is available, stages it, configures it, and then initiates an install. This step creates 21 EC2 images and you must have increased your AWS account limit in order to perform this.
