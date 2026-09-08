# AWS VPC and Private Connectivity Terraform Module

Terraform configuration for an AWS VPC with public and private subnets, internet access for public workloads, and VPC endpoints that support Systems Manager without requiring public access to private instances.

## Architecture

- VPC with configurable CIDR range
- Public and private subnets
- Internet gateway for public routing
- EC2 and Systems Manager interface endpoints
- Security groups for controlled endpoint access
- Outputs for VPC, subnet, and endpoint identifiers

## Prerequisites

- Terraform 1.5+
- AWS CLI credentials with permission to manage the declared resources
- An AWS region and a valid AMI ID for the EC2 resource, if enabled

## Usage

    terraform init
    terraform fmt -check
    terraform validate
    terraform plan -out=tfplan
    terraform apply tfplan

Destroy only in a disposable environment with terraform destroy.

## Inputs

- region: AWS deployment region; default us-west-1
- ami: AMI ID used by the EC2 resource; required when enabled
- cidr_block: VPC CIDR range; default 10.0.0.0/16
- public_subnet_cidr: public subnet CIDR; default 10.0.1.0/24
- private_subnet_cidr: private subnet CIDR; default 10.0.2.0/24

## Security guidance

Review the plan before applying, keep state in an encrypted remote backend with locking, avoid hard-coded credentials, and restrict endpoint security groups to required VPC clients.
