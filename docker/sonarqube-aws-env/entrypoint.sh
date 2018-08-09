#!/bin/bash
chown -R sonarqube:sonarqube $SONARQUBE_HOME

if [ -z "$AWS_REGION" ]; then
export AWS_REGION="eu-west-1"
fi

/usr/local/bin/aws-env exec ./bin/run.sh