provider "aws" {
  region = "us-east-1"
}

# Load SSH Public Key
resource "aws_key_pair" "my_key" {
  key_name   = "assignkey"
  public_key = file("assignkey.pub") # Ensure assignkey.pub exists in the Terraform directory
}

# Fetch the default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch the available subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Select the first subnet from the available subnets
data "aws_subnet" "selected" {
  id = tolist(data.aws_subnets.default.ids)[0]
}

# Security Group for SSH and Web Access, associate it with the VPC
resource "aws_security_group" "web_sg" {
  name_prefix = "web_sg_"
  vpc_id      = data.aws_vpc.default.id  # Explicitly specify the VPC

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH access
  }

  ingress {
    from_port   = 8080
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow app access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Deploy EC2 Instance
resource "aws_instance" "web_server" {
  ami                         = "ami-0c02fb55956c7d316" # Amazon Linux 2 AMI
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnet.selected.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.my_key.key_name  # Attach SSH Key
  security_groups         = [aws_security_group.web_sg.id]  # Use the security group ID

  tags = {
    Name = "web_server"
  }

  depends_on = [aws_security_group.web_sg]  # Ensure security group is created first
}

# Create Amazon ECR Repositories
resource "aws_ecr_repository" "webapp_repo" {
  name = "webapp_repo"
}

resource "aws_ecr_repository" "mysql_repo" {
  name = "mysql_repo"
}
