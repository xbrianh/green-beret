data "aws_caller_identity" "current" {}

locals {
  common_tags = "${map(
    "service"   , "${var.AI_SERVICE}",
    "owner", "${var.AI_OWNER}"
  )}"
  aws_tags = "${map(
    "Name"      , "${var.AI_SERVICE}",
  )}"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-eoan-19.10-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

data "aws_secretsmanager_secret_version" "private_key" {
  secret_id = "${var.GREEN_BERET_AWS_KEY_PAIR_SECRET_ID}"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "green-beret" {
  name   = "${var.AI_SERVICE}"
  vpc_id = "${data.aws_vpc.default.id}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "ssh"
  }
  ingress {
    from_port   = 60000
    to_port     = 61000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "mosh"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags   = merge(local.common_tags, local.aws_tags)
}

resource "aws_instance" "green-beret" {
  ami             = "${data.aws_ami.ubuntu.id}"
  instance_type   = "m5.large"
  key_name        = "${var.GREEN_BERET_AWS_KEY_PAIR_NAME}"
  security_groups = ["${aws_security_group.green-beret.name}"]
  root_block_device {
    volume_size = 16
  }
  tags            = merge(local.common_tags, local.aws_tags)
  volume_tags     = merge(local.common_tags, local.aws_tags)
}

resource "null_resource" "server_configuration" {
  triggers = {
    instance_id = "${aws_instance.green-beret.id}"
  }

  connection {
    host        = "${aws_instance.green-beret.public_ip}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${data.aws_secretsmanager_secret_version.private_key.secret_string}"
  }

  provisioner "file" {
    source      = "setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "remote-exec" {
    inline = ["chmod +x /tmp/setup.sh && sudo /tmp/setup.sh"]
  }
}

output "instance-id" {
  value = "${aws_instance.green-beret.id}"
}
