resource "tls_private_key" "main" {
  algorithm   = "RSA"
  rsa_bits    = 2048
}

resource "aws_key_pair" "node-group" {
  key_name   = var.defaults.environment
  public_key = tls_private_key.main.public_key_openssh
}

data "aws_ami" "default" {
  most_recent = true
  owners = [ "137112412989" ]

  filter {
    name   = "name"
    values = [ "amzn2-ami-hvm-2.0.????????.?-x86_64-gp2" ]
  }
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.default.id
  instance_type = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[0]

  associate_public_ip_address = true

  key_name = aws_key_pair.node-group.key_name

  subnet_id = aws_subnet.public[0].id
  vpc_security_group_ids = [ aws_eks_cluster.main.vpc_config[0].cluster_security_group_id ]

  tags = {
    Name = format("%s-bastion", var.defaults.environment)
    environment = var.defaults.environment
  }
}

output "ssh_private_key" {
  value = tls_private_key.main.private_key_pem
}