## Sonarqube

[![Build Status](https://travis-ci.com/telia-oss/terraform-aws-sonarqube.svg?branch=master)](https://travis-ci.com/telia-oss/terraform-aws-sonarqube)

This terraform module creates a standalone instance of Sonarqube that is preconfigured to use Github oauth.

The module does the following:
* Deploys Sonarqube in its own VPC with a postgres database
* Configures Github oauth
* Creates a new admin user
* Removes the defualt admin user

#### Prerequisites
This module assumes that the AWS account this is deployed to has both a Route53 zone set up and a wildcard certificate for that zone so that this can be launched behind SSL

#### Quick start
To get a working Sonarqube installation up and running complete the following steps
1. copy the default example inlcuding the init folder
2. run terraform apply in the init folder and record the arn output.
3. in the example.tf file:
    replace the value for parameters_key_arn  with the value returned in the previous step
    replace the value for certificate_arn with the arn of your wildcard certificate
    replace the value for route53_zone with the name of your route53 hosted zone
4. create the following ssm parameters in your AWS account and encrypt them using the key create above.

| ssm parameter name| description |
|--- |--- |
|/\<name_prefix\>/github-auth-enabled |set to true|
|  /\<name_prefix\>/github-client-id | obtained from github|
|  /\<name_prefix\>/github-client-secret |obtained from github|
|  /\<name_prefix\>/github-organizations |github organisation for ouath|
|  /\<name_prefix\>/admin-username |may only contain url safe chars|
|  /\<name_prefix\>/admin-password |may only contain url safe chars|

5. run terraform apply


