# Cloud Lab
This repo contains Terraform and Ansible for building a lab in the cloud.

There are currently two workspaces defined:

cs-demo: has several workloads across aws and azure that are a good demonstration for CloudSecure.  
pce: optional and could be utilized to setup a custom SNC demo PCE in AWS along with a few other workloads.

Pre-reqs
--------

Install terraform and ansible.

The Terraform and some of the Ansible plays rely on the AWS and Azure cli. Google or ask
ChatGPT how to set this up.

For AWS, you'll want to setup at least your se account and optionally your personal accont (if used for route53).
Your credentials file would look something like this.

» more ~/.aws/credentials  
[se15]  
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX  
aws_secret_access_key = YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY  
[personal]  
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX  
aws_secret_access_key = YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY

You'll need a registered domain name and hosted zone setup in route53. The Terraform setup has a variable so you can point to
either a domain you have registered in your personal aws account, or you can point to your se account.
Easiest thing is to just register a domain via route53 ($14/year) in your personal or se account.

Terraform
---------

All of the variables to customize a particular setup can be found in terraform/terraform.tfvars.template.
Copy this file to terraform.tfvars in the same directory and review the entries
and edit as appropriate for your environment.

The terraform setup relys on making sure you have your workspace set to the same name as the configs
defined in terraform/config-files. The two profiles currently contained in the repo are "cs-demo"
and "pce".

To setup cs-demo, you'd do something like this:

Copy terraform/terraform.tfvars.template to terraform/terraform.tfvars and edit terraform/terraform.tfvars.

cd terraform  
terraform init  
terraform workspace new cs-demo  
terraform workspace list (verify you're in the correct workspace)  
terraform plan (will give a list of all the assets that will be created)  
terrafrom apply (will create everything)

The above can take a while, and may fail the first couple times when creating the aws <-> azure vpn.
Just run it again if it fails and it should eventually work.

A couple things that aren't yet in the terraform setup that you may want to do manually in the aws console.

1) Create an AWS Loadbalancer and load balance the 3 fin-prd web servers.
2) If you setup the pce workspace as well, setup a peering relationship between jump-vpc and pce-vpc

Ansible
-------

All of the variables to customize a particular setup can be found in ansible/vars.yaml.template.
Copy this file to vars.yaml in the same directory and review the entries
and edit as appropriate for your environment.

There are several setup scripts that can be utilized to run ansible.

01-setup-hosts.sh - Run this first to setup the local host files.  
02-setup-cs-demo.sh - This will setup the traffic in the cs-demo.   
03-update-pce.sh - This runs an update on the pce workloads.  
04-setup-pce.sh - This sets up the pce.
