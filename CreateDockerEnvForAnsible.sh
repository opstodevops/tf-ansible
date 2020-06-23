#!/bin/bash

# access_key="${1}"
# secret_key="${2}"
# region="${3}"

echo ====================================
# promopt for AWS credentials
read -sp 'access_key: ' access_key
echo
read -sp 'secret_key: ' secret_key
echo
read -p 'region: ' region
echo ====================================
echo
echo "=== Creating CentOS container for managing instances in ${region} ==="

docker container run --rm --network=host \
-it --name control \-v "$(pwd)":/ansible -w /ansible \
-e "AWS_ACCESS_KEY_ID=${access_key}" \
-e "AWS_SECRET_ACCESS_KEY=${secret_key}" \
-e "AWS_REGION=${region}" \
ansible:centos

