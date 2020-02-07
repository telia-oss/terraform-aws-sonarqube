#!/bin/bash

if [ -z "$AWS_REGION" ] && [ -z "$AWS_DEFAULT_REGION" ]; then
    export AWS_REGION="eu-west-1"
fi
./start-with-params.sh
