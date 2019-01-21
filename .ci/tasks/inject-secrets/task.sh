#!/bin/sh
export DIR="${PWD}"
cp -a ${DIR}/source/. ${DIR}/secret-source/
cd ${DIR}/secret-source/examples/${directory}
pwd
sed -i 's#<test-account-id>#'${AWS_ACCOUNT_ID}'#g' main.tf
sed -i 's#<kms-key-id>#'${KMS_KEY_ID}'#g' main.tf
sed -i 's#<route53-zone>#'${ROUTE53_ZONE}'#g' main.tf
