## Ansible Ad-hoc commands for environment prep

### Creating and distributing SSH key
```
ssh-keygen

ansible all -k -K -m authorized_keys \
-a "user='USER' state='present' \
key='{{ lookup('file','/home/USER/.ssh/id_rsa.pub' )}}'"
```
### Allowing USER for passwordless sudo access
```
echo "USERTOADD ALL=(root) NOPASSWD: ALL" > FILENAME
sudo visudo -cf FILENAME #SYNTAX check
ansible all -b -K -m copy -a "src=FILENAME dest='/etc/sudoers.d/FILENAME'"
```
### Sample ~/.vimrc
```
set bg=dark
set number
autocmd FileType yaml setlocal ai et ts=2 sw=2 cuc cul
```
### Configure Ansible Inventory for WINRM connectivity
```
[win]
win1 ansible_host=172.16.2.5 
win2 ansible_host=172.16.2.6

# Default connection to WinRM on 5985
[win:vars]
ansible_user=Administrator
ansible_password=SomeSecretPassword!!!
ansible_connection=winrm
ansible_winrm_port=5985
ansible_winrm_server_cert_validation=ignore

# Specifying connection to WinRM on 5986
ansible_user=Administrator
ansible_password=SomeSecretPassword!!!
ansible_connection=winrm
ansible_winrm_port=5986
ansible_winrm_server_cert_validation=ignore

# Specifying connection to WinRM on 5986 & using NTLM for authentication
ansible_user=Administrator
ansible_password=SomeSecretPassword!!!
ansible_connection=winrm
ansible_winrm_port=5986
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
ansible-vault create private.yml
ansible-playbook --ask-vault-pass -e "user_name=USER" playbook.yml
```
### Convert .PEM to .PUB
```
ssh-keygen -y -f ansible-key-innovation.pem > ansible-key-innovation.pub
```
### Python shell break
```
python -c 'import pty; pty.spawn("/bin/sh")'
```
### Creating ec2-user on Ubuntu
```
ansible ubuntu -b -m user -a "user=ec2-user state=present" -u ubuntu
ansible ubuntu -b -m authorized_key -a "user=ec2-user state=present key={{ lookup('file','/ansible/ansible-key-innovation.pub' )}}" -u ubuntu
```



