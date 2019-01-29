#!/bin/sh
set -eu
export DIR="${PWD}"
cp -a ${DIR}/source/. ${DIR}/secret-source/
PARAMETERS_KEY_ARN=`cat terraform-out-init/terraform-out.json | jq -r '.parameters_key_arn'`
cd ${DIR}/secret-source/examples/${directory}
sed -i 's#<parameters-key-arn>#'${PARAMETERS_KEY_ARN}'#g' main.tf
