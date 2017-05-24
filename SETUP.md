# Automation of Pivotal Cloud Foundry deployment to AWS
*** 

This project enables you to fully automate (without any manual intervention) the deployment of Pivotal Cloud Foudry to Amazon Web Services using the default (basic) configuration using Ansible, as explained here: 
https://docs.pivotal.io/pivotalcf/1-10/customizing/cloudform.html
Once deployed, you will be able to modify the basic configuration and customize the different aspect of the Pivotal Cloud Foudry. 

### How the Project is organized
There are 8 Ansible roles, each of which carry a particular task in the deployment of Pivotal Cloud Foudry to AWS.  
1. cloudformation: Deploys the CloudFormation template for PCF on AWS as explained here:
https://docs.pivotal.io/pivotalcf/1-10/customizing/cloudform-template.html
2. opsmanagerdeploy: Deploys and Start an AWS EC2 VM containg PCF's Operations Manager: 
https://docs.pivotal.io/pivotalcf/1-10/customizing/cloudform-om-deploy.html
3. directorconfig: Partially Configures Operations Manager Director (Bosh) using Ops Manager Rest API as explained here: 
https://docs.pivotal.io/pivotalcf/1-10/customizing/cloudform-om-config.html
* A bug in PCF's Operations Manager REST API does not allow this role to fully configure Bosh. In order to get around this bug, the following role modifies the Installation.yml file directly on Operations Manager VM. This is not normally recommended, but allows us to work around the bug. 
4. modifyserver: modifies Installation.yml in Operation Manager VM to finish the configuration of bosh. 
5. directorinstall: Triggers the installation of Operations Manager Director (Bosh) 
6. elasticruntimeupload: Uploads the image for PCF's Elastic Runtime to Operations Manager as explained here: 
https://docs.pivotal.io/pivotalcf/1-10/customizing/cloudform-er-config.html
7. elasticruntimeconfig: Configures PCF's Elastic Runtime as explained here:
https://docs.pivotal.io/pivotalcf/1-10/customizing/cloudform-er-config.html
8. createpushuser: creates a Cloud Foudry Super user to be used as administrator.

In the following section, the project setup is explained in detail. 

### Setting up the Project: 

##### Prerequisites
At a minimum, you need the following before you can use this project: 
>  An AWS Account in which, you are able to run more than 20 VMs (the default) in the region where you are planning to deploy Pivotal Cloud Foudry.

In order to run this project, you have two options: 
(i) (recommended) Use an Existing AWS AMI which already included all of the required dependencies to act as your Ansible Controller.
(ii) Prepare a linux enviornment in which you can run Ansible (and all of its dependencies). 

#### Using an Exsting AWS AMI for your Ansible Controller. 
if you wish to use this AMI (ami-025f2b14 for us-east-1), email me at saedalav@gmail.com so that I can share this AMI with you. Once you have the AMI, you must create an instance from this AMI and give it (at minimum) full EC2 and RDS IAM access. The modify the project (As explained in the following sections) and run the job. 
You may use the following project to further automate the deployment of Ansible Controller:
https://github.com/saedalav/ansible_controller_pcfdeployment

#### Prepare your own environment
if you chose to prepare your own linux environment, you must have the following dependencies installed: 
1) Python 2.7+ 
2) Ansible 2.0+
3) Python Boto Library (Boto, Boto3, Botodev)
4) CF-UAAC (Cloud Foudry User Accound and Authentication CLI) See here:
https://github.com/cloudfoundry/cf-uaac
5) CF-CLI (Cloud Foudry Command Line Interface) See here: 
https://github.com/cloudfoundry/cli
Additionally, you need: 
6) Pivotal Cloud Foundry Elastic Runtime 1.10.x Binaries. See here: https://network.pivotal.io/products/elastic-runtime
7) You must set AWS_SECRET_ACCESS_KEY and AWS_ACCESS_KEY environment variables. See here:
http://boto.cloudhackers.com/en/latest/boto_config_tut.html
8) One or more SSH key(s) for accessing EC2 instances in the desired region obtained from AWS.

### How to Modify the project
The project is setup such that for each role, you should only need to modfiy the vars/main.yml file unless you have a particular need that must be address before PCF is deployed. Otherwise, most of other changes can be applied after PCF is up and running using Ops Manager. 
Therefore, for each role: 
1) Modify the vars/main.yml 
Note: Many variables must be consitent accross all roles. For example, once you have set the region to us-east-1, you cannot change the value across roles.
Also note that while some variables can be left as default, others must be changed. In the following section, each variable is explained and user is told if they should change this value or not.

2) run the role in the order presented here. 
Alternatively, you can run deployAll.yml playbook to run all roles at once. However, this may not be the best idea if this is your first time. 

You must first download this project locally: 
```sh
$ git clone https://github.com/saedalav/pcfdeployment.git
$ cd pcfdeployment
```

#### Step 1: cloudformation Role
Modify roles/cloudformation/vars/main.yml. For example: 
```sh
vim roles/cloudformation/vars/main.yml
```

The following varibles can be configured: 


| Variable        | Value          | Remarks   |
| :-------------: |:-------------:| :-----:|
| StackName     | The name of the clodu formation stack | Leave it as is |
| Region      | the region in which PCF is deployed      |    |
| TemplateLocation | the cloudformation template location      |    You must leave it as is |
| NATKeyPai | the SSH Key used by NAT VM | Must choose an existing key in your AWS | 
| NATInstanceType | NAT VM Instance Type | Leave it as is | 
| OpsManagerIngress | Range of Ingress IPs for Ops Manager | Leave it as is |
| RdsDBName | name of the RDS DB for Ops Man | Up to the user | 
| RdsUserName |  username of RDS DB | Up to the user | 
| RDsPassword | password for RDS | Chose a secure password or user Vault | 
| SSLCertificateARN | the ARN for the AWS Certificate Manager | See Note 1 | 
| OpsManagerTemplate | the location of the OpsManagerTemplate | See Note 2 | 

* Note 1: You must create a Certificate to be used for your PCF using AWS Certificate Manger, capture its ARN and use it here. For more information, see here: 
http://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-server-cert.html#create-cert
* Note 2: If you leave this as blank, the default OpsManager template will be used which is highly recommended. If you wish to modify that, then provide the S3 location for a new ops-manager.json file. 

#### Step 2: opsmanagerdeploy
Modify roles/opsmanagerdeploy/vars/main.yml. For example: 
```sh
vim roles/opsmanagerdeploy/vars/main.yml
```

The following varibles can be configured: 


| Variable        | Value          | Default is accepted?   |
| :-------------: |:-------------:| :-----:|
|StackName | the name of the CloudFormation stack | Must match the value in previous Role |
|Region | the region to which PCF is deployed | Must match the value in previous Role |
|NatKeyPair | the SSH Key used to access Ops Manager | Provide an existing EC2 SSH Key | 
|OpsMangInstanceType | the InstanceType for Ops Manager | User to choose. default is sufficient|
|AMIID | the AMI ID for the existing Ops Man AMI | see Note 1 | 
| Route53Zone | Route 53 Domain to be used with Ops Man | User to choose | 
| Route53Record | Route 53 Record to be used with Ops Man | User to choose | 
| Route53Type | Route 53 Record Type | Leave it as is | 
| DecryptionPassphrase | Decrpytion Passphrase for Ops Man's data | User to choose or use Vault |
| AdminUsername | Username to be used for Ops Man | User to choose | 
| AdminPassword | Password for Ops Man Admin | User to choose or user Vault | 
* Note 1: This must a pre-existing AMI ID provided by Pivotal for the Operations Manager of your choise. For a list of available AMI in each region, see: 
https://network.pivotal.io/products/ops-manager

#### Step 3: directorconfig
Modify roles/directorconfig/vars/main.yml. For example: 
```sh
vim roles/directorconfig/vars/main.yml
```

The following varibles can be configured: 


| Variable        | Value          | Default is accepted?   |
| :-------------: |:-------------:| :-----:|
|StackName | the name of the CloudFormation stack | Must match the value in previous Role |
|DecryptionPassphrase | Decrpytion Passphrase for Ops Man's data | Must match the value in previous Role |
| AdminUsername | Username to be used for Ops Man | Must match the value in previous Role | 
| AdminPassword | Password for Ops Man Admin | Must match the value in previous Role | 
| Route53Record | Route 53 Record for Ops Man | Must match the value in previous Role | 
|Region | the region to which PCF is deployed | Must match the value in previous Role |
|KeyPair | the SSH Key used to access Ops Manager | Must match the value in previous Role | 
|ssh_private_key | SSH Key for BOSH | See Note 1 |
* Note 1: You must enter the value in the following format: 
"{{ lookup('file', 'path/to/yourkey/yourkey.pem') }}"


#### Step 4: modifyserver
Variable are the same as the previous role.
```sh
cp roles/directorconfig/vars/main.yml roles/modifyserver/vars/main.yml
```




#### Step 5: directorInstall
Variable are the same as the previous role.
```sh
cp roles/directorconfig/vars/main.yml roles/directorInstall/vars/main.yml
```

#### Step 6: elasticruntimeupload
Modify roles/elasticruntimeupload/vars/main.yml. For example: 
```sh
vim roles/elasticruntimeupload/vars/main.yml
```

All variables are the same as previous step except for the following: 


| Variable        | Value          | Default is accepted?   |
| :-------------: |:-------------:| :-----:|
|ElasticRuntimeFilePath | the location fo the Elastic Runtime Binaries | See Note 1 |
Note 1: You must download your desired version of PCF Elastic Runtime from here:
https://network.pivotal.io/products/elastic-runtime
and then set ElasticRuntimeFilePath.


#### Step 7: elasticruntimeconfig
Modify roles/elasticruntimeconfig/vars/main.yml. For example: 
```sh
vim roles/elasticruntimeconfig/vars/main.yml
```

All variables are the same as previous step except for the following new variables: 


| Variable        | Value          | Default is accepted?   |
| :-------------: |:-------------:| :-----:|
|ElasticRuntimeDBAEmail | Email Address for Elastic Runtime DBA | User to choose a value |
|RuntimeAppDomain|The domain in which CF Apps run | See Note 1 |
|RuntimeSystemDomain| The domain in which CF System apps run | See Note 1 |
* Note 1: For PCF's recommandation, please see Step 4: Add CNAME Record for Your Custom Domain in:
https://docs.pivotal.io/pivotalcf/1-10/customizing/cloudform-er-config.html
 

#### Step 8: createpushuser
Modify roles/createpushuser/vars/main.yml. For example: 
```sh
vim roles/createpushuser/vars/main.yml
```

The following varibles can be configured: 


| Variable        | Value          | Default is accepted?   |
| :-------------: |:-------------:| :-----:|
|pushUserName| the primary username to execute cf push | User to choose | 
|pushPassword| password for the primary user| User to choose or use Vault|
|pushEmail| Primary user's email address | User to choose| 
|defautOrg|the default Org for the primary user | User to choose |
|dfaultSpace|the default Space for the primary user | User to choose|

Once all variables are set, you may either run each role separately (recommended if it is your first time) or run all the roles sequencially useing deployAll.yml 
```sh
ansible-playbook deployAll.yml -vvv
```

Alternatively, you can run (or schedule job.sh) which runs the ansble command and emails the user the result (if a mail client is setup. Following variables must be setup: 
email= The email address at which the job result are to be emailed
output_path= The location of the output file
root_directory= The project's root path name

### What Exactly each Role does: 
In this section, we briefly go over the key tasks in each role 
#### Step 1: cloudformation Role
> Runs a Cloudformation module task to deploy PCF's CloudFormation Template  
#### Step 2: opsmanagerdeploy Role
> Gathers information from the output of the cloudformation stack   
> Runs an ec2 module to lunch the Ops Manager Instance   
> Wati for Ops Manager to become available   
> Creates a Route53 record   
> Uses Ops Manager API to configure the Admin Username and password for Ops Manager. As this task also decrypt the data, it is time consuming and as such, Ansible wait on it and retries 3 times  
> Once the Ops Manager Security is configured, Ansible paused for another 2 minutes so that the Authentication Service starts. This step is needed if all roles are executed sequencially and ensures that authentication is running before attempting to use the API   
#### Step 3: directorconfig Role
> Obtains a UAA_ACCESS_TOKEN from Ops Manager so that it can access its REST API
> Regather the CloudFormation Stack facts to be used as input in configuration
> Uses Ops Manager Rest API to configure Bosh 
#### Step 4: modifyserver Role
> As mentioned, this role  SSH into the Ops Manager VM, decrypts the Installation.yml file, modifies its content (to get around the Rest API bug where the value of Database and S3 cannot be set to external) and decrpyts Instllation.yml and places back into its location. After this, Bosh is ready to be installed
#### Step 5: directorinstall Role
> This step trigers the installation of Bosh, then waits for 10 minutes during which Bosh Installation continues. After 10 minutes, it uses the rest API to see if the Installation was successful or not. If it was incomplete, it wait for another minute before checking again. The wait if only necessary if the steps are executed sequencially. 
#### Step 6: elasticruntimeupload Role
> This step uses Operation Managers API to upload Elastic Runtime to Ops Manager. This is a very time consuming and I/O intensive task. 
#### Step 7: Elasticruntime Config
> This role first reobtains API keys to ensure it can access Ops Manager Rest API
> It retrieves Cloudformation facts and sets variables
> It then uses Operation Manager Rest API to configure Elastic Runtime and prepare it for Installation.
> It also creates two CNAME record in Route 53. If you already have the required CNAME and do not need to configure it in AWS, you may remove this step. 
> It then triggers the installation of Elastic Runtime
> It wait for 1 hour before checking the status of the Installation. If it has not completed, it wait for 5 minutes before rechecking (up to 20 times). 
#### Step 8: createpushuser 
> This role uses CF-UAAC to create a User and grant all rights to that user (Admin)
> It then creates the default Org and Space






