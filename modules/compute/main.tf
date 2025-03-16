
data "template_cloudinit_config" "create_unified_user" {
  part {
    content_type = "text/cloud-config"
    content      = <<-CLOUDCONFIG
      #cloud-config
      users:
        - name: "${var.ec2_user_name}"
          groups: sudo
          sudo: ALL=(ALL) NOPASSWD:ALL
          shell: /bin/bash
          ssh_authorized_keys:
            - ${tls_private_key.clab_ssh.public_key_openssh}
      CLOUDCONFIG
  }
}

resource "aws_instance" "clab_instance" {
  ami = var.clab_ami
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  security_groups = [var.security_groups]
  user_data = data.template_cloudinit_config.create_unified_user.rendered
  key_name = aws_key_pair.clab_keypair.key_name

  tags = {
    "Name" = var.name
  }

  provisioner "local-exec" {
    command = "echo 'Instance created with key: ${aws_key_pair.clab_keypair.key_name}.pem'"
  }

  provisioner "local-exec" {
      command = "chmod +x create_host_file.sh && ./create_host_file.sh ${self.public_ip}"
  }

  depends_on = [null_resource.check_key_file]
}

# Generate a new SSH key pair
resource "tls_private_key" "clab_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# Create an AWS key pair using the generated SSH key
resource "aws_key_pair" "clab_keypair" {
  key_name = var.key_pair_name
  public_key = tls_private_key.clab_ssh.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "clab_keypair" {
  content  = tls_private_key.clab_ssh.private_key_pem
  filename = "${path.root}/${aws_key_pair.clab_keypair.key_name}.pem"
}

resource "null_resource" "set_key_permissions" {
  provisioner "local-exec" {
    command = "chmod 600 ${path.root}/${aws_key_pair.clab_keypair.key_name}.pem"
  }

  depends_on = [local_file.clab_keypair]
}

# Check if the key file exists
resource "null_resource" "check_key_file" {
  provisioner "local-exec" {
    command = "test -f ${aws_key_pair.clab_keypair.key_name} || touch ${aws_key_pair.clab_keypair.key_name}.pem"
  }
}

# resource "null_resource" "shell_file_setup" {
#   provisioner "local-exec" {
#     command = "chmod +x create_host_file.sh && ./create_host_file.sh ${aws_instance.clab_instance.public_ip}"
#   }
# }

output "clab_keypair_path" {
  value = local_file.clab_keypair.filename
}
