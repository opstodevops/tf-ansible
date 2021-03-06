##################################################################################
# VARIABLES
##################################################################################

# variable "aws_access_key" {}
# variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "admin_username" {}
variable "admin_password" {}

variable "region" {
  type    = string
  default = "us-east-1"
}

# variable "vpc_cidr_range" {
#   type    = string
#   default = "10.0.0.0/16"
# }

# variable "public_subnets" {
#   type    = list(string)
#   default = ["10.0.0.0/24", "10.0.1.0/24"]
# }

# variable "database_subnets" {
#   type    = list(string)
#   default = ["10.0.8.0/24", "10.0.9.0/24"]
# }

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
  version                 = "~>2.0"
  region                  = var.region
  # alias                   = "east"
  profile                 = "nonprod" # instead of default
  shared_credentials_file = "~/.aws/credentials"
  # assume_role {
  #   role_arn = "${lookup(var.assume_roles, var.aws_account_alias)}"
  # }
}

##################################################################################
# DATA SOURCES
##################################################################################

# data "aws_caller_identity" "east" {
#   provider = aws.east
# }

data "aws_availability_zones" "azs" {}

data "aws_ami" "redhat-linux" {
  most_recent = true
  owners      = ["309956199498"]

  filter {
    name   = "name"
    values = ["RHEL-7.6_HVM_GA*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  # owners = [ "amazon", "microsoft" ] 
  owners = ["self"]

  filter {
    name   = "name"
    values = ["WIN2019-CUSTOM-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
        name   = "virtualization-type"
    values = ["hvm"]
  }
}

##################################################################################
# RESOURCES
##################################################################################

#This uses the default VPC.  It WILL NOT delete it on destroy.
resource "aws_default_vpc" "default" {
  
  tags = {
    Name = "default VPC for us-east-1a"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = element(data.aws_availability_zones.azs.names, 0)

  tags = {
    Name = "default subnet for us-east-1a"
    Environment = "${terraform.workspace}"
    Tier = "Public"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = element(data.aws_availability_zones.azs.names, 1)

  tags = {
    Name = "default subnet for us-east-1b"
    Environment = "${terraform.workspace}"
    Tier = "Public"
  }
}

resource "aws_default_subnet" "default_az3" {
  availability_zone = element(data.aws_availability_zones.azs.names, 2)

  tags = {
    Name = "default subnet for us-east-1c"
    Environment = "${terraform.workspace}"
    Tier = "Public"
  }
}

resource "tls_private_key" "tlsauth" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2key" {
  # key_name   = var.key_name
  key_name   = "${var.key_name}-${terraform.workspace}"
  public_key = tls_private_key.tlsauth.public_key_openssh
  tags = {
    Name = "ansible-key-${terraform.workspace}"
  }
}

resource "null_resource" "get_keys" {

  provisioner "local-exec" {
    command     = "echo '${tls_private_key.tlsauth.public_key_openssh}' > ./ansible-public-key-${terraform.workspace}.rsa"
  }

  provisioner "local-exec" {
    command     = "echo '${tls_private_key.tlsauth.private_key_pem}' > ./ansible-key-${terraform.workspace}.pem"
  }

  provisioner "local-exec" {
    command     = "chmod 600 ./ansible-key-${terraform.workspace}.pem"
  }

}

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "2.33.0"

#   name = "dev-vpc"
#   cidr = var.vpc_cidr_range

#   azs = slice(data.aws_availability_zones.azs.names, 0, 2) # Grabbing 2 AZs from the list of AZs

#   # Public Subnets
#   public_subnets = var.public_subnets

#   # Database Subnets
#   database_subnets = var.database_subnets
#   database_subnet_group_tags = {
#     subnet_type = "database"
#   }

#   tags = {
#     Environment = "dev"
#     Region      = "east"
#     Team        = "infra"
#   }

# }

resource "aws_security_group" "allow_ssh" {
  name        = "tf_ssh_demo-${terraform.workspace}"
  description = "Allow ports for ssh"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_rdp" {
  name        = "tf_rdp_demo-${terraform.workspace}"
  description = "Allow ports for rdp and winrm"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nix_servers" {
  ami                    = data.aws_ami.redhat-linux.id
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.ec2key.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  # subnet_id = aws_default_subnet.default_az1.id
  subnet_id = element(list(aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id), count.index)
  count = 2

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)

  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "web-${count.index}-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

# resource "aws_instance" "web02" {
#   ami                    = data.aws_ami.redhat-linux.id
#   instance_type          = "t2.medium"
#   key_name               = var.key_name
#   vpc_security_group_ids = [aws_security_group.allow_ssh.id]
#   subnet_id = aws_default_subnet.default_az3.id

#   connection {
#     type        = "ssh"
#     host        = self.public_ip
#     user        = "ec2-user"
#     private_key = file(var.private_key_path)

#   }

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Name = "web02"
#   }
# }

resource "aws_instance" "dc01" {
  ami                    = data.aws_ami.windows.id
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.ec2key.id
  vpc_security_group_ids = [aws_security_group.allow_rdp.id]
  subnet_id = aws_default_subnet.default_az2.id
  iam_instance_profile   = aws_iam_instance_profile.customssmprofile.name
  user_data = <<EOF
<powershell>
  # Set Administrator password
  $admin = [adsi]("WinNT://./administrator, user")
  $admin.psbase.invoke("SetPassword", "${var.admin_password}")
</powershell>
EOF

  connection {
    type        = "winrm"
    port        = 5986
    https       = true
    insecure    = true
    host        = self.public_ip
    user        = var.admin_username
    password    = var.admin_password
    private_key = file(var.private_key_path)
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "dc01-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_instance" "app01" {
  ami                    = data.aws_ami.windows.id
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.ec2key.id
  vpc_security_group_ids = [aws_security_group.allow_rdp.id]
  subnet_id = aws_default_subnet.default_az3.id
  iam_instance_profile   = aws_iam_instance_profile.customssmprofile.name
  user_data = <<EOF
<powershell>
  # Set Administrator password
  $admin = [adsi]("WinNT://./administrator, user")
  $admin.psbase.invoke("SetPassword", "${var.admin_password}")
</powershell>
EOF

  connection {
    type        = "winrm"
    port        = 5986
    https       = true
    insecure    = true
    host        = self.public_ip
    user        = var.admin_username
    password    = var.admin_password
    private_key = file(var.private_key_path)

  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "app01-${terraform.workspace}"
    Environment = "${terraform.workspace}"
  }
}

resource "aws_iam_instance_profile" "customssmprofile" {
  name = "customssmprofile-${terraform.workspace}"
  role = aws_iam_role.customssmrole.name
}

resource "aws_iam_role" "customssmrole" {
  name = "customssmrole-${terraform.workspace}"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
tags = {
      Environment = "${terraform.workspace}"
  }
}

data "aws_iam_policy" "awsssmmanagedinstancecore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "awsssmmanaged-policy-attach" {
  role       = aws_iam_role.customssmrole.name
  policy_arn = data.aws_iam_policy.awsssmmanagedinstancecore.arn
}


##################################################################################
# OUTPUT
##################################################################################

# output "web01_public_ip" {
#   value = aws_instance.web01.public_ip
# }

# output "web02_public_ip" {
#   value = aws_instance.web02.public_ip
# }

output "linux_servers_public_ip" {
  value = aws_instance.nix_servers.*.public_ip
  # value = [for linux in aws_instance.nix_servers : linux.public_ip]
}

output "dc01_public_ip" {
  value = aws_instance.dc01.public_ip
}

output "app01_public_ip" {
  value = aws_instance.app01.public_ip
}

output "ec2key_name" {
  value = aws_key_pair.ec2key.key_name
}

# output "vpc_id" {
#   value = module.vpc.vpc_id
# }

# output "db_subnet_group" {
#   value = module.vpc.database_subnet_group
# }

# output "public_subnets" {
#   value = module.vpc.public_subnets
# }