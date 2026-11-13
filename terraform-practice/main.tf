terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "ssh_cidr" {
  description = "Your public IP in CIDR form, e.g. 203.0.113.5/32"
  type        = string

  validation {
    condition     = var.ssh_cidr != "0.0.0.0/0"
    error_message = "Don't open SSH to the whole internet. Use your own IP with /32."
  }
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

provider "aws" {
  region = var.region
}

# Latest Amazon Linux 2023 image, looked up for the chosen region
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_key_pair" "this" {
  key_name   = "terraform-practice"
  public_key = file(pathexpand(var.public_key_path))
}

resource "aws_security_group" "ssh" {
  name        = "terraform-practice-ssh"
  description = "Allow SSH from my IP"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "vm" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = {
    Name = "terraform-practice-vm"
  }
}

output "public_ip" {
  value = aws_instance.vm.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/id_ed25519 ec2-user@${aws_instance.vm.public_ip}"
}