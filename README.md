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

### Configure Ansible Inventory for WINRM connectivity
```
[win]
172.16.2.5 
172.16.2.6 

[win:vars]
ansible_user=Administrator
ansible_password=SomeSecretPassword!!!
ansible_connection=winrm
ansible_winrm_server_cert_validation=ignore
```