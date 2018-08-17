#!/bin/bash
if [ -z "$AWS_REGION" ]; then
AWS_REGION="eu-west-1"
fi
/usr/local/bin/aws-env exec ./start.sh