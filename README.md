# tf-ansible
Code repository for Terraform and Ansible project

### Packer Build
```
packer validate windows_ami_packer.json
packer build example.json
packer build \
    -var 'aws_access_key=YOUR ACCESS KEY' \
    -var 'aws_secret_key=YOUR SECRET KEY' \
    example.json
```
### Running Docker with Ansible and AWS tools
```
docker build --rm -t ansible:centos .
docker container run --rm -it --name control -v "$(pwd)":/ansible -w /ansible --env "AWS_ACCESS_KEY_ID=YOUR ACCESS KEY" --env "AWS_SECRET_ACCESS_KEY=YOUR SECRET KEY" --env "AWS_REGION=us-east-1" ansible:centos
```
### Configuring Docker container for using PEM key
```
chmod 600 YOUR_PEM.key
exec ssh-agent bash
ssh-add YOUR_PEM.key
```
### Configure Ansible Inventory for WINRM connectivity
```
[win]
win1 ansible_host=172.16.2.5 
win2 ansible_host=172.16.2.6

[win:vars]
ansible_user=Administrator
ansible_password=SomeSecretPassword!!!
ansible_connection=winrm
ansible_winrm_transport=ntlm
ansible_winrm_server_cert_validation=ignore
```
### Ansible PING module use for Linux and Windows
```
ansible LINUX -m ping -u ec2-user
ansible WINDOWS -m win_ping -u ec2-user
```
### Ansible file and string encryption
```
ansible-vault encrypt_string --vault-password-file vault_pass.txt 'ClearTXTPassword' --name 'PASSWORD_VARIABLE'
ansible-playbook playbook.yml --vault-password-file <vault_pass.txt>
ansible-vault encrypt <playbook.yml>
ansible-playbook --ask-vault-pass <playbook.yml>
```
