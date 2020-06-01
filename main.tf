##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {}
variable "admin_username" {}
variable "admin_password" {}
variable "region" {
  default = "us-east-1"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

##################################################################################
# DATA
##################################################################################

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
  owners = [ "self" ]

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

}

resource "aws_security_group" "allow_ssh" {
  name        = "tf_ssh_demo"
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
  name        = "tf_rdp_demo"
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

resource "aws_instance" "web01" {
  ami                    = data.aws_ami.redhat-linux.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)

  }

  tags = {
    Name = "web01"
  }
}

resource "aws_instance" "web02" {
  ami                    = data.aws_ami.redhat-linux.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)

  }

  tags = {
    Name = "web02"
  }
}

resource "aws_instance" "dc01" {
  ami                    = data.aws_ami.windows.id
  instance_type          = "t2.medium"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_rdp.id]
  user_data = <<EOF
<powershell>
  # Set Administrator password
  $admin = [adsi]("WinNT://./administrator, user")
  $admin.psbase.invoke("SetPassword", "${var.admin_password}")
  # Configure WINRM for Ansible
  $url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
  $file = "$env:temp\ConfigureRemotingForAnsible.ps1"
  (New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
  powershell.exe -ExecutionPolicy ByPass -File $file -Verbose
</powershell>
EOF

  connection {
    type        = "winrm"
    insecure    = true
    host        = self.public_ip
    user        = var.admin_username
    password    = var.admin_password
    private_key = file(var.private_key_path)
  }

  # provisioner "file" {
  #   source      = "./ConfigureRemotingForAnsible.ps1"
  #   destination = "C:\\Users\\ADMINI~1\\AppData\\Local\\Temp\\2\\"
  # }

  # provisioner "remote-exec" {
  #   inline = [
  #     "powershell -ExecutionPolicy Unrestricted -File C:\\Users\\ADMINI~1\\AppData\\Local\\Temp\\2\\ConfigureRemotingForAnsible.ps1 -Verbose"
  #   ]
  # }

  tags = {
    Name = "dc01"
  }
}

resource "aws_instance" "app01" {
  ami                    = data.aws_ami.windows.id
  instance_type          = "t2.medium"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_rdp.id]
  user_data = <<EOF
<powershell>
  # Set Administrator password
  $admin = [adsi]("WinNT://./administrator, user")
  $admin.psbase.invoke("SetPassword", "${var.admin_password}")
  # Configure WINRM for Ansible
  $url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
  $file = "$env:temp\ConfigureRemotingForAnsible.ps1"
  (New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
  powershell.exe -ExecutionPolicy ByPass -File $file -Verbose
</powershell>
EOF

  connection {
    type        = "winrm"
    insecure    = true
    host        = self.public_ip
    user        = var.admin_username
    password    = var.admin_password
    private_key = file(var.private_key_path)

  }

  tags = {
    Name = "app01"
  }
}

resource "aws_instance" "db01" {
  ami                    = data.aws_ami.windows.id
  instance_type          = "t2.medium"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.allow_rdp.id]
  user_data = <<EOF
<powershell>
  # Set Administrator password
  $admin = [adsi]("WinNT://./administrator, user")
  $admin.psbase.invoke("SetPassword", "${var.admin_password}")
  # Configure WINRM for Ansible
  $url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
  $file = "$env:temp\ConfigureRemotingForAnsible.ps1"
  (New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
  powershell.exe -ExecutionPolicy ByPass -File $file -Verbose
</powershell>
EOF

  connection {
    type        = "winrm"
    insecure    = true
    host        = self.public_ip
    user        = var.admin_username
    password    = var.admin_password
    private_key = file(var.private_key_path)

  }

  tags = {
    Name = "db01"
  }
}

##################################################################################
# OUTPUT
##################################################################################

output "web01_public_ip" {
  value = aws_instance.web01.public_ip
}

output "web02_public_ip" {
  value = aws_instance.web02.public_ip
}

output "dc01_public_ip" {
  value = aws_instance.dc01.public_ip
}

output "db01_public_ip" {
  value = aws_instance.db01.public_ip
}

output "app01_public_ip" {
  value = aws_instance.app01.public_ip
}