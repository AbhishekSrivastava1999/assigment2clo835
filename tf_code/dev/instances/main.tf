#  Defining the cloud provider
provider "aws" {
  region = "us-east-1"
}

# AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Retrieving default VPC
data "aws_vpc" "default" {
  default = true
}

# Defining tags
locals {
  default_tags = merge(module.globalvars.default_tags, { "env" = var.env })
  prefix       = module.globalvars.prefix
  name_prefix  = "${local.prefix}-${var.env}"
}

# Retrieving global vars from tf module
module "globalvars" {
  source = "../../modules/globalvars"
}

# Reference subnet provisioning 
resource "aws_instance" "k8s" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = lookup(var.instance_type, var.env)
  key_name                    = aws_key_pair.ass02.key_name
  vpc_security_group_ids      = [aws_security_group.sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = data.aws_iam_instance_profile.lab_profile.name
  user_data  			            = file("install.sh")
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-Amazon-Linux"
    }
  )
}


# Adding SSH key to the EC2
resource "aws_key_pair" "ass02" {
  key_name   = local.name_prefix
  public_key = file("${local.name_prefix}.pub")
}

# Security Group
resource "aws_security_group" "sg" {
  name        = "allow_ssh_web"
  description = "Allow SSH and Web inbound traffic"
  vpc_id      = data.aws_vpc.default.id

dynamic "ingress" {
    for_each = var.sg_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "tcp"
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-sg"
    }
  )
}


# AWS ECR Repository Creation
resource "aws_ecr_repository" "ecr_repository" {
  for_each             = var.ecr_repo
  name                 = "${local.name_prefix}-${each.value}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

data "aws_iam_instance_profile" "lab_profile" {
  name = "LabInstanceProfile"
}

