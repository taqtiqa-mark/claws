terraform {
  required_version = ">=1.5.2"
    required_providers {
        aws = {
          source  = "hashicorp/aws"
          version = "5.5.0"
        }
        tls = {
          source  = "hashicorp/tls"
          version = "4.0.4"
        }
        null = {
          source  = "hashicorp/null"
          version = "3.2.1"
        }
        http = "3.4.0"
        template = "2.2.0"
    }
}

locals {
  yaml_file = yamldecode(file("./vars.yml"))
}

provider "aws" {
  region = local.yaml_file.region
}

module "network" {
  source = "./modules/network"
  vpc_cidr_block = local.yaml_file.vpc_cidr_block
  subnet_cidr_block = local.yaml_file.subnet_cidr_block
  region = local.yaml_file.region
}


# resource "aws_key_pair" "generated_key" {
#   key_name   = local.yaml_file.key_pair_name
#   public_key = tls_private_key.clab_ssh.public_key_openssh
# }

# # Check if the key file exists
# resource "null_resource" "check_key_file" {
#   provisioner "local-exec" {
#     command = "test -f ${local_file.private_key.filename} || touch ${local_file.private_key.filename}"
#   }
# }

# # Create an EC2 instance using the generated key pair
# resource "aws_instance" "clab_instance" {
#   ami           = local.yaml_file.ami_id
#   instance_type = local.yaml_file.ec2_instance_type
#   key_name      = aws_key_pair.generated_key.key_name
#   subnet_id     = module.network.subnet_id
#   security_groups = [module.network.security_group_id]

#   tags = {
#     Name = "clab-instance"
#   }

  # provisioner "local-exec" {
  #   command = "echo 'Instance created with key: ${local_file.private_key.filename}'"
  # }

#   depends_on = [null_resource.check_key_file]
# }

module "compute" {
  source = "./modules/compute"
  instance_type = local.yaml_file.ec2_instance_type
  clab_ami = local.yaml_file.ami_id
  key_pair_name = local.yaml_file.key_pair_name
  subnet_id = module.network.subnet_id
  security_groups = module.network.security_group_id
  name = local.yaml_file.clab_naming_convention
  ec2_user_name = local.yaml_file.ec2_user_name
}

# Output the private key filename
output "private_key_path" {
  value = module.compute.clab_keypair_path
}