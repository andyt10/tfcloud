data "aws_ami" "amz_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_vpc" "vpc" {
  cidr_block       = local.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name  = "${local.name_prefix}vpc"
    Owner = local.owner
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name  = "${local.name_prefix}igw"
    Owner = local.owner
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name  = "${local.name_prefix}rt"
    Owner = local.owner
  }
}

resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.sn.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route" "inet_route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.rt.id
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_network_acl" "nacl" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_network_acl_rule" "nacl_ingress_http" {
  network_acl_id = aws_network_acl.nacl.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_subnet" "sn" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = local.sn_cidr

  tags = {
    Name  = "${local.name_prefix}sn"
    Owner = local.owner
  }

  depends_on = [
    aws_vpc.vpc
  ]
}

resource "aws_security_group" "sg" {
  name        = "${local.name_prefix}sg"
  description = "Terraform Study - Security Group"
  vpc_id      = aws_vpc.vpc.id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name  = "${local.name_prefix}sg"
    Owner = local.owner
  }

  depends_on = [
    aws_vpc.vpc
  ]
}

resource "aws_security_group_rule" "sg_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "sg_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.sg.id
}

resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.amz_linux.id
  instance_type               = local.instance_type
  subnet_id                   = aws_subnet.sn.id
  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.sg.id
  ]

  root_block_device {
    delete_on_termination = true
    volume_size           = 50
    volume_type           = "gp2"
  }

  tags = {
    Name  = "${local.name_prefix}ec2"
    Owner = local.owner
  }

  depends_on = [
    aws_subnet.sn,
    aws_security_group.sg,
  ]
}