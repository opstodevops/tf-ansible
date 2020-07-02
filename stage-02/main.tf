##################################################################################
# VARIABLES
##################################################################################

# variable "aws_access_key" {}
# variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "admin_username" {}
variable "admin_password" {}

variable "region_1" {
  type = string
  default = "us-east-1"
}

variable "region_2" {
  type = string
  default = "us-west-1"
}

variable "vpc_cidr_range_east" {
  type = string
  default = "10.10.0.0/16"
}

variable "public_subnets_east" {
  type = list(string)
  default = ["10.10.0.0/24", "10.10.1.0/24"]
}

variable "database_subnets_east" {
  type = list(string)
  default = ["10.10.8.0/24", "10.10.9.0/24"]
}

variable "vpc_cidr_range_west" {
  type = string
  default = "10.11.0.0/16"
}

variable "public_subnets_west" {
  type = list(string)
  default = ["10.11.0.0/24", "10.11.1.0/24"]
}

variable "database_subnets_west" {
  type = list(string)
  default = ["10.11.8.0/24", "10.11.9.0/24"]
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
  region     = var.region_1
  alias = "east"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "production"
}

provider "aws" {
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
  region     = var.region_2
  alias = "west"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "production"
}

##################################################################################
# DATA SOURCES
##################################################################################

data "aws_caller_identity" "east" {
  provider = aws.east
}

data "aws_caller_identity" "west" {
  provider = aws.west
}

data "aws_availability_zones" "azs_east" {
  provider = aws.east
}

data "aws_availability_zones" "azs_west" {
  provider = aws.west
}

# data "aws_ami" "redhat-linux" {
#   most_recent = true
#   owners      = ["309956199498"]

#   filter {
#     name   = "name"
#     values = ["RHEL-7.6_HVM_GA*"]
#   }

#   filter {
#     name   = "root-device-type"
#     values = ["ebs"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

# data "aws_ami" "windows" {
#   most_recent = true
#   # owners = [ "amazon", "microsoft" ] 
#   owners = ["self"]

#   filter {
#     name   = "name"
#     values = ["WIN2019-CUSTOM-*"]
#   }

#   filter {
#     name   = "root-device-type"
#     values = ["ebs"]
#   }

#   filter {
#         name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

##################################################################################
# RESOURCES
##################################################################################

#This uses the default VPC.  It WILL NOT delete it on destroy.
# resource "aws_default_vpc" "default" {

# }

# resource "tls_private_key" "tlsauth" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# resource "aws_key_pair" "ec2key" {
#   key_name   = var.key_name
#   public_key = tls_private_key.tlsauth.public_key_openssh
#   tags = {
#     Name = "ansible-key"
#   }
# }

# resource "null_resource" "get_keys" {

#   provisioner "local-exec" {
#     command     = "echo '${tls_private_key.tlsauth.public_key_openssh}' > ./ansible-public-key.rsa"
#   }

#   provisioner "local-exec" {
#     command     = "echo '${tls_private_key.tlsauth.private_key_pem}' > ./ansible-key.pem"
#   }

#   provisioner "local-exec" {
#     command     = "chmod 600 ./ansible-key.pem"
#   }

# }

module "vpc_east" {
  source = "terraform-aws-modules/vpc/aws"
  version = "2.33.0"

  name = "prod-vpc-east"
  cidr = var.vpc_cidr_range_east

  azs = slice(data.aws_availability_zones.azs_east.names, 0, 2) # Grabbing 2 AZs from the list of AZs
  
  # Public Subnets
  public_subnets = var.public_subnets_east

  # Database Subnets
  database_subnets = var.database_subnets_east
  database_subnet_group_tags = {
    subnet_type = "database"
  }

  providers = {
    aws = aws.east
  }

  tags = {
    Environment = "prod"
    Region = "east"
    Team = "infra"
  }

}

module "vpc_west" {
  source = "terraform-aws-modules/vpc/aws"
  version = "2.33.0"

  name = "prod-vpc-west"
  cidr = var.vpc_cidr_range_west

  azs = slice(data.aws_availability_zones.azs_west.names, 0, 2) # Grabbing 2 AZs from the list of AZs
  
  # Public Subnets
  public_subnets = var.public_subnets_west

  # Database Subnets
  database_subnets = var.database_subnets_west
  database_subnet_group_tags = {
    subnet_type = "database"
  }

  providers = {
    aws = aws.west
  }

  tags = {
    Environment = "prod"
    Region = "west"
    Team = "infra"
  }

}
# resource "aws_security_group" "allow_ssh" {
#   name        = "tf_ssh_demo"
#   description = "Allow ports for ssh"
#   vpc_id      = aws_default_vpc.default.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = -1
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "allow_rdp" {
#   name        = "tf_rdp_demo"
#   description = "Allow ports for rdp and winrm"
#   vpc_id      = aws_default_vpc.default.id

#   ingress {
#     from_port   = 3389
#     to_port     = 3389
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 5985
#     to_port     = 5985
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   ingress {
#     from_port   = 5986
#     to_port     = 5986
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = -1
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_instance" "web01" {
#   ami                    = data.aws_ami.redhat-linux.id
#   instance_type          = "t2.medium"
#   key_name               = var.key_name
#   vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  
#   connection {
#     type        = "ssh"
#     host        = self.public_ip
#     user        = "ec2-user"
#     private_key = file(var.private_key_path)

#   }

#   tags = {
#     Name = "web01"
#   }
# }

# resource "aws_instance" "dc01" {
#   ami                    = data.aws_ami.windows.id
#   instance_type          = "t2.medium"
#   key_name               = var.key_name
#   vpc_security_group_ids = [aws_security_group.allow_rdp.id]
#   iam_instance_profile   = aws_iam_instance_profile.customssmprofile.name
#   user_data = <<EOF
# <powershell>
#   # Set Administrator password
#   $admin = [adsi]("WinNT://./administrator, user")
#   $admin.psbase.invoke("SetPassword", "${var.admin_password}")
# </powershell>
# EOF

#   connection {
#     type        = "winrm"
#     port        = 5986
#     https       = true
#     insecure    = true
#     host        = self.public_ip
#     user        = var.admin_username
#     password    = var.admin_password
#     private_key = file(var.private_key_path)
#   }

#   tags = {
#     Name = "dc01"
#   }
# }

# resource "aws_instance" "app01" {
#   ami                    = data.aws_ami.windows.id
#   instance_type          = "t2.medium"
#   key_name               = var.key_name
#   vpc_security_group_ids = [aws_security_group.allow_rdp.id]
#   iam_instance_profile   = aws_iam_instance_profile.customssmprofile.name
#   user_data = <<EOF
# <powershell>
#   # Set Administrator password
#   $admin = [adsi]("WinNT://./administrator, user")
#   $admin.psbase.invoke("SetPassword", "${var.admin_password}")
# </powershell>
# EOF

#   connection {
#     type        = "winrm"
#     port        = 5986
#     https       = true
#     insecure    = true
#     host        = self.public_ip
#     user        = var.admin_username
#     password    = var.admin_password
#     private_key = file(var.private_key_path)

#   }

#   tags = {
#     Name = "app01"
#   }
# }

# resource "aws_iam_instance_profile" "customssmprofile" {
#   name = "customssmprofile"
#   role = aws_iam_role.customssmrole.name
# }

# resource "aws_iam_role" "customssmrole" {
#   name = "customssmrole"
#   path = "/"

#   assume_role_policy = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Action": "sts:AssumeRole",
#             "Principal": {
#                "Service": "ec2.amazonaws.com"
#             },
#             "Effect": "Allow",
#             "Sid": ""
#         }
#     ]
# }
# EOF
# tags = {
#       Environment = "dev"
#   }
# }

# data "aws_iam_policy" "awsssmmanagedinstancecore" {
#   arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_role_policy_attachment" "awsssmmanaged-policy-attach" {
#   role       = aws_iam_role.customssmrole.name
#   policy_arn = data.aws_iam_policy.awsssmmanagedinstancecore.arn
# }


##################################################################################
# OUTPUT
##################################################################################

# output "web01_public_ip" {
#   value = aws_instance.web01.public_ip
# }

# output "dc01_public_ip" {
#   value = aws_instance.dc01.public_ip
# }

# output "app01_public_ip" {
#   value = aws_instance.app01.public_ip
# }

# output "ec2key_name" {
#   value = aws_key_pair.ec2key.key_name
# }

output "vpc_id_east" {
  value = "module.vpc_east.vpc.id"
}

output "vpc_id_west" {
  value = "module.vpc_west.vpc.id"
}

output "db_subnet_group" {
  value = "module.vpc.database_subnet_group"
}

output "public_subnets" {
  value = "module.vpc.public_subnets"
}