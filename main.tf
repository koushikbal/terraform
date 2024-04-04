provider "aws" {
  region = "us-west-1"  # Change to your desired region
}

# Define VPC
resource "aws_vpc" "terraform_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform_vpc"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "terraform_igw"
  }
}

# Attach IGW to VPC
resource "aws_internet_gateway_attachment" "igw_attachment" {
  vpc_id             = aws_vpc.terraform_vpc.id
  internet_gateway_id = aws_internet_gateway.igw.id
}

# Define public subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-1a"

  tags = {
    Name = "public_subnet"
  }
}

# Create route table for public subnet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.terraform_vpc.id

  tags = {
    Name = "public_route_table"
  }
}

# Create route to IGW for public subnet
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate public subnet with route table
resource "aws_route_table_association" "public_route_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_route_table.id
}

# Define private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.terraform_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-1b"

  tags = {
    Name = "private_subnet"
  }
}

# Define security group for VPC endpoints
resource "aws_security_group" "vpc_end_sg" {
  vpc_id      = aws_vpc.terraform_vpc.id
  description = "Security group for VPC endpoints"
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc_end_sg"
  }
}

# Define security group for EC2 instance
resource "aws_security_group" "instance_sg" {
  vpc_id      = aws_vpc.terraform_vpc.id
  description = "Security group for EC2 instance"
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance_sg"
  }
}

# Create VPC endpoints
resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id              = aws_vpc.terraform_vpc.id
  service_name        = "com.amazonaws.us-west-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_end_sg.id]

  tags = {
    Name = "ssm_endpoint"
  }
}

resource "aws_vpc_endpoint" "ssmmessages_endpoint" {
  vpc_id              = aws_vpc.terraform_vpc.id
  service_name        = "com.amazonaws.us-west-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_end_sg.id]

  tags = {
    Name = "ssmmessages_endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2_endpoint" {
  vpc_id              = aws_vpc.terraform_vpc.id
  service_name        = "com.amazonaws.us-west-1.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_end_sg.id]

  tags = {
    Name = "ec2_endpoint"
  }
}

resource "aws_vpc_endpoint" "ec2messages_endpoint" {
  vpc_id              = aws_vpc.terraform_vpc.id
  service_name        = "com.amazonaws.us-west-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpc_end_sg.id]

  tags = {
    Name = "ec2messages_endpoint"
  }
}

# Define IAM role for SSM
resource "aws_iam_role" "ssm_role" {
  name = "ssm_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "ssm_role"
  }
}

# Define IAM policy for SSM
resource "aws_iam_policy" "ssm_policy" {
  name        = "ssm_policy"
  description = "Policy for SSM role"
  
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": "ssm:*",
      "Resource": "*"
    }]
  })

  tags = {
    Name = "ssm_policy"
  }
}

# Attach policy to IAM role
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

# Define IAM instance profile
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm_instance_profile"

  tags = {
    Name = "ssm_instance_profile"
  }
  
  roles = [aws_iam_role.ssm_role.name]  # Attach IAM role directly to instance profile
}

# Define EC2 instance
resource "aws_instance" "terraform_ec2" {
  ami                         = "ami-05c969369880fa2c2" # Replace with your desired AMI
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private.id
  security_groups             = [aws_security_group.instance_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name  # Use the correct instance profile name

  tags = {
    Name = "terraform_ec2_instance"
  }
}
