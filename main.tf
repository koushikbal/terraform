provider "aws" {
  region = "us-west-1"
}

# Create VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "terraform_vpc"
  }
}

# Create public subnet
resource "aws_subnet" "terraform_public_subnet" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-1a"
  tags = {
    Name = "terraform_public_subnet"
  }
}

# Create private subnet
resource "aws_subnet" "terraform_private_subnet" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-1a"
  tags = {
    Name = "terraform_private_subnet"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "terraform_igw" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags = {
    Name = "terraform_igw"
  }
}

# Attach internet gateway to public subnet
resource "aws_route_table" "terraform_public_route" {
  vpc_id = aws_vpc.terraform_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_igw.id
  }

  tags = {
    Name = "terraform_public_route"
  }
}

resource "aws_route_table_association" "terraform_public_route_association" {
  subnet_id      = aws_subnet.terraform_public_subnet.id
  route_table_id = aws_route_table.terraform_public_route.id
}

# Create security group for VPC endpoints
resource "aws_security_group" "terraform_vpc_endpoints_sg" {
  vpc_id = aws_vpc.terraform_vpc.id
  tags = {
    Name = "terraform_vpc_endpoints_sg"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Open port 443 in security group for VPC endpoints
resource "aws_security_group_rule" "terraform_vpc_endpoints_sg_rule" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.terraform_vpc_endpoints_sg.id
  description       = "Allow inbound traffic on port 443 for VPC endpoints"
}

# Create VPC endpoints
resource "aws_vpc_endpoint" "terraform_ssm_endpoint" {
  vpc_id              = aws_vpc.terraform_vpc.id
  service_name        = "com.amazonaws.us-west-1.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.terraform_vpc_endpoints_sg.id]
  subnet_ids          = [aws_subnet.terraform_private_subnet.id]
  private_dns_enabled = true  # Enable private DNS name resolution
    tags = {
    Name = "terraform_ssm_endpoint"
  }
}

resource "aws_vpc_endpoint" "terraform_ssm_messages_endpoint" {
  vpc_id              = aws_vpc.terraform_vpc.id
  service_name        = "com.amazonaws.us-west-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.terraform_vpc_endpoints_sg.id]
  subnet_ids          = [aws_subnet.terraform_private_subnet.id]
  private_dns_enabled = true  # Enable private DNS name resolution
  tags = {
    Name = "terraform_ssm_messages_endpoint"
  }
}

resource "aws_vpc_endpoint" "terraform_ec2_endpoint" {
  vpc_id              = aws_vpc.terraform_vpc.id
  service_name        = "com.amazonaws.us-west-1.ec2"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.terraform_vpc_endpoints_sg.id]
  subnet_ids          = [aws_subnet.terraform_private_subnet.id]
  private_dns_enabled = true  # Enable private DNS name resolution
  tags = {
    Name = "terraform_ec2_endpoint"
  }
}

resource "aws_vpc_endpoint" "terraform_ec2_messages_endpoint" {
  vpc_id              = aws_vpc.terraform_vpc.id
  service_name        = "com.amazonaws.us-west-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.terraform_vpc_endpoints_sg.id]
  subnet_ids          = [aws_subnet.terraform_private_subnet.id]
  private_dns_enabled = true  # Enable private DNS name resolution
  tags = {
    Name = "terraform_ec2_messages_endpoint"
  }
}

# Create a security group allowing inbound traffic on port 443 for EC2 instance
resource "aws_security_group" "terraform_ec2_sg" {
  name        = "terraform_ec2-sg"
  description = "Security group for EC2 with port 443 open"
  vpc_id      = aws_vpc.terraform_vpc.id
  tags = {
    Name = "terraform_ec2_sg"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create IAM instance profile for SSM access
resource "aws_iam_instance_profile" "terraform_ssm_instance_profile" {
  name = "terraform_ssm_instance_profile"
  role = aws_iam_role.terraform_ssm_role.name
  tags = {
    Name = "terraform_ssm_instance_profile"
  }
}

# Create IAM role for SSM access
resource "aws_iam_role" "terraform_ssm_role" {
  name               = "terraform_ssm_role"
  tags = {
    Name = "terraform_ssm_role"
  }
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach SSM managed policy to the IAM role
resource "aws_iam_role_policy_attachment" "terraform_ssm_policy_attachment" {
  role       = aws_iam_role.terraform_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create EC2 instance in a private subnet
resource "aws_instance" "terraform_example_instance" {
  ami                    = "ami-id"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.terraform_private_subnet.id
  security_groups        = [aws_security_group.terraform_ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.terraform_ssm_instance_profile.name
  tags = {
    Name = "terraform_example_instance"
  }
}
