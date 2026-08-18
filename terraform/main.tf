terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
  backend "s3" {
    bucket = "alex-log-app-tf-state-2026"
    key = "terraform.tfstate"
    region = "eu-north-1"
    encrypt = true
    use_lockfile = true
  }
}

data "aws_ami" "ami_ubuntu_os" {
  most_recent=true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

output "ami_output" {
  value = data.aws_ami.ami_ubuntu_os.id
}
output "subnet_id" {
  value = aws_subnet.subnet_test.id
}

output "security_group_id" {
  value = aws_security_group.security_group_test_EC2.id
}

resource "aws_instance" "ec2_instance" {
    ami = data.aws_ami.ami_ubuntu_os.id
    instance_type = var.instance_type
    vpc_security_group_ids = [aws_security_group.security_group_test_EC2.id]
    subnet_id = aws_subnet.subnet_test.id
    key_name = "Key_pair_EC2"
    associate_public_ip_address = true
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y docker.io docker-compose-v2 git awscli


    systemctl enable docker
    systemctl start docker

    usermod -aG docker ubuntu

    git clone https://github.com/AlexCosmeen/proiect_logs_devops.git /opt/log-app

    cd /opt/log-app
    mkdir -p secrets
    aws secretsmanager get-secret-value \
    --secret-id log-app/db-user \
    --query SecretString \
    --output text > secrets/db_user.txt

    aws secretsmanager get-secret-value \
    --secret-id log-app/db-name \
    --query SecretString \
    --output text > secrets/db_name.txt

    aws secretsmanager get-secret-value \
    --secret-id log-app/db-password \
    --query SecretString \
    --output text > secrets/db_password.txt
    chmod 600 secrets/*.txt
    docker compose up -d 
    
    EOF
  
}

resource "aws_secretsmanager_secret" "database" {
  for_each = var.database_secrets
  name = each.value
  tags = {
    Project = "log-app"
  }
}

resource "aws_s3_bucket" "log_app_bucket" {
  bucket = "alex-log-app-tf-state-2026"
}

