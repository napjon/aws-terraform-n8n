# Overview

Terraform config to launch n8n instance on top of AWS EC2


# Prequisites

1. Register to AWS, retrieve access key from AWS console
2. Make sure you have key-pair if you later would like SSH access to the instance
3. Make sure you have AWS CLI installed and configured

# Installation

1. git clone this repository
2. cd into the directory
3. Replace access key with your own in main.tf
4. Replace username and region you want to use in `terraform.tfvars`
5. `terraform init`
6. `terraform apply`
7. You will be asked n8n password. Enter it and press enter.
8. Type `yes` to confirm deployments.
9. Use public IP address to connect to n8n. Please wait about one minute for n8n to be ready.
10. Access n8n with configured username and password.

