# Terraform Configuration

This Terraform configuration creates a VPC with public and private subnets, internet gateway, VPC endpoints for SSM, EC2, and their respective security groups.

## Usage

1. Install Terraform ([Terraform Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli))
2. Configure your AWS credentials ([AWS CLI Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html))
3. Initialize Terraform:
   terraform init
4.Review the Terraform plan:
  terraform plan
5.Apply the Terraform configuration:
  terraform apply

Inputs
region: The AWS region where resources will be created. (Default: us-west-1)
ami: The AMI ID for the EC2 instance.
cidr_block: The CIDR block for the VPC. (Default: 10.0.0.0/16)
public_subnet_cidr: The CIDR block for the public subnet. (Default: 10.0.1.0/24)
private_subnet_cidr: The CIDR block for the private subnet. (Default: 10.0.2.0/24)

Outputs
vpc_id: The ID of the created VPC.
public_subnet_ids: The IDs of the public subnets.
private_subnet_ids: The IDs of the private subnets.
internet_gateway_id: The ID of the internet gateway.
ssm_endpoint_id: The ID of the SSM VPC endpoint.
ec2_endpoint_id: The ID of the EC2 VPC endpoint.
ssm_messages_endpoint_id: The ID of the SSM Messages VPC endpoint.
ec2_messages_endpoint_id: The ID of the EC2 Messages VPC endpoint.


Adjust the inputs and outputs section according to your specific requirements and configurations.
