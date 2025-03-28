resource "aws_vpc" "clab_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    "Name" = "clab vpc"
  }
}

resource "aws_internet_gateway" "clab_igw" {
  vpc_id = aws_vpc.clab_vpc.id
}

resource "aws_route_table" "clab_routetable" {
  vpc_id = aws_vpc.clab_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.clab_igw.id
  }
}

resource "aws_route_table_association" "rt_association" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.clab_routetable.id
}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.clab_vpc.id
  cidr_block = var.subnet_cidr_block
  map_public_ip_on_launch = true
}
resource "aws_network_acl_association" "associate_nacl_subnet" {
  network_acl_id = aws_network_acl.clab_nacl.id
  subnet_id = aws_subnet.public.id
}

resource "aws_network_acl" "clab_nacl" {
  vpc_id = aws_vpc.clab_vpc.id
  tags = {
    "Name" = "clab nacl"
  }

  egress {
      action = "allow"
      from_port = 0
      to_port = 0
      cidr_block = "0.0.0.0/0"
      protocol = "-1"
      rule_no = 100
  }
  ingress {
    action = "allow"
    from_port = 0
    to_port = 0
    cidr_block = "0.0.0.0/0"
    rule_no = 100
    protocol = "-1"
  }
  }
  resource "aws_security_group" "allow_ssh" {
  name = "clab_allow_ssh"
  description = "Allows SSH access from instance connect"
  vpc_id = aws_vpc.clab_vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [data.aws_ip_ranges.region_specific_instance_connect.cidr_blocks[0], "${local.ip_address}/32"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

  output "subnet_id" {
    value = aws_subnet.public.id
  }

  output "security_group_id" {
    value = aws_security_group.allow_ssh.id
  }