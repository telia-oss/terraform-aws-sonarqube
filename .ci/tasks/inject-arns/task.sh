#!/bin/sh
export DIR="${PWD}"
cp -a ${DIR}/source/. ${DIR}/secret-source/
cd ${DIR}/secret-source/examples/${directory}
PARAMETERS_KEY_ARN=`cat terraform-out-init/terraform-out.json | jq -r '.vpc_id.value'`
CERTIFICATE_ARN=`cat terraform-out-init/terraform-out.json | jq -r '.vpc_id.value'`
ROUTE53_ZONE=`cat terraform-out-init/terraform-out.json | jq -r '.vpc_id.value'`
sed -i 's#<parameters-key-arn>#'${PARAMETERS_KEY_ARN}'#g' main.tf
sed -i 's#<certificate-arn>#'${CERTIFICATE_ARN}'#g' main.tf
