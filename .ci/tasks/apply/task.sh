#!/bin/sh
export DIR="${PWD}"
cp -a ${DIR}/source/. ${DIR}/secret-source/
cd ${DIR}/secret-source/examples/${directory}
rm -rf .terraform
terraform init
terraform apply --auto-approve
terraform output -json > ${DIR}/terraform-out/terraform-out.json