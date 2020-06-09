data "aws_caller_identity" "current" {}

locals {
  tags = jsondecode(var.GREEN_BERET_INFRA_TAGS)
  instance_tags = merge(local.tags, {Name=var.GREEN_BERET_INSTANCE_NAME})
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
  secret_id = var.GREEN_BERET_AWS_KEY_PAIR_SECRET_ID
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "green-beret" {
  name   = var.GREEN_BERET_INSTANCE_NAME
  vpc_id = data.aws_vpc.default.id
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
  tags = local.tags
}

data "aws_iam_policy_document" "green-beret" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "green-beret" {
  name               = var.GREEN_BERET_INSTANCE_NAME
  assume_role_policy = data.aws_iam_policy_document.green-beret.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "node_power_user" {
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  role       = aws_iam_role.green-beret.name
}

resource "aws_iam_instance_profile" "green-beret" {
  name = var.GREEN_BERET_INSTANCE_NAME
  role = aws_iam_role.green-beret.name
}

resource "aws_instance" "green-beret" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.GREEN_BERET_AWS_INSTANCE_TYPE
  key_name             = var.GREEN_BERET_AWS_KEY_PAIR_NAME
  iam_instance_profile = aws_iam_instance_profile.green-beret.name
  security_groups      = [aws_security_group.green-beret.name]
  root_block_device {
    volume_size = 32
  }
  tags                 = local.instance_tags
  volume_tags          = local.instance_tags
}

resource "null_resource" "instance_config" {
  triggers = {
    instance_id = aws_instance.green-beret.id
  }

  connection {
    host        = aws_instance.green-beret.public_ip
    type        = "ssh"
    user        = "ubuntu"
    private_key = data.aws_secretsmanager_secret_version.private_key.secret_string
  }

  provisioner "file" {
    source      = "../../instance_config/setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "file" {
    source      = "../../instance_config/bashrc"
    destination = "/tmp/bashrc"
  }

  provisioner "file" {
    source      = "../../instance_config/vimrc"
    destination = "~/.vimrc"
  }

  provisioner "remote-exec" {
    inline = ["chmod +x /tmp/setup.sh && /tmp/setup.sh",
              "cat /tmp/bashrc >> ~/.bashrc"]
  }
}

output "instance-id" {
  value = aws_instance.green-beret.id
}
