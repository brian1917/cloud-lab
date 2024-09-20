# Cloud Lab
This repo contains Terraform and Ansible for building a CloudSecure demo or a cloud-hosted lab.

## Terraform
The first step is building the infrastructure via Terraform. This lab has been tested on `Terraform v1.8.5`.

Each lab should use its own Terraform workspace. See below for useful commands:
- See all Terraform workspaces: `terraform workspace list`
- Create a new Terraform workspace: `terraform workspace new se32`
- Switch Terraform workspaces: `terraform workspace select se32`

The lab is designed to be governed by two configuration files: 1 for AWS and 1 for Azure. The config files should reside in the `terraform/config-files` directory. The format should be `{terraform-workspace}-{csp}.yaml.` For example, if my Terraform workspace is `se32`, the lab config files should `terraform/config-files/se32-aws.yaml` amd `terraform/config-files/se32-azure.yaml`

The two example config files in this repo have annotated the parameters that need to be configured. The `se32` example has networks and workloads for building a demo for CloudSecure. This Terraform targets AWS and Azure. The `lab` example is simpler with AWS only workloads for a PCE and example workloads. (Note - you still need the Azure config file, but it's mainly empty)

Terraform will require credentials in ~/.aws/credentials to connect to your account. See below for example format of this file:
```
» more ~/.aws/credentials  
[se32]  
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX  
aws_secret_access_key = YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY  
[personal]  
aws_access_key_id = XXXXXXXXXXXXXXXXXXXX  
aws_secret_access_key = YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
```

### Route53
Terraform creates DNS entries via Route53. The `route53AWSProfile` parameter in the AWS config file specifies the AWS profile to use for DNS. It's recommend to use a personal AWS account with registered DNS ($14/yr). If you use `poc.segmentationpov.com` DNS, you might need to change all VM hostnames to not conflict with other DNS entries.

### Example commands to get started
```
cd terraform  
terraform init  
terraform workspace new se32
terraform workspace list (verify your in the correct workspace)  
terraform plan (will give a list of all the assets that will be created)  
terrafrom apply (will create everything)
```

The above can take a while, and may fail the first couple times when creating the aws <-> azure vpn.
Run it again if it fails and it should eventually work.


## Ansible
This lab was tested on `ansible [core 2.16.3]`.
Once the infrastructure is built, use Ansible to configure it. There are some simple bash scripts to run the configuration.

1. Update your `ansible/vars.yaml` file.
2. Generate your hosts file by running `ansible/01-setup-hosts.sh`
3. Depending on your lab either run `ansible/02-setup-cs-demo.sh` or `ansible/04-setup-pce.sh.`