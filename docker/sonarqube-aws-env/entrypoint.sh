#!/bin/bash
chown -R sonarqube:sonarqube $SONARQUBE_HOME

if [ -z "$AWS_REGION" ] && [ -z "$AWS_DEFAULT_REGION" ]; then
export AWS_REGION="eu-west-1"
fi
exec gosu sonarqube ./start-with-params.sh
