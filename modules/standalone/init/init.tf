data "aws_caller_identity" "current" {}

resource "aws_kms_key" "sonarqube-parameters" {
  description = "KMS key for encrypting parameters passed to sonarqube."
  tags        = "${var.tags}"
}

resource "aws_kms_alias" "key-alias" {
  name          = "alias/sonarqube-parameters"
  target_key_id = "${aws_kms_key.sonarqube-parameters.id}"
}

resource "random_string" "rds_username" {
  length  = 10
  special = false
  number  = false
}

resource "random_string" "rds_password" {
  length  = 16
  special = true
}

resource "aws_ssm_parameter" "rds_username" {
  name   = "/${var.prefix}/rds-username"
  type   = "SecureString"
  value  = "${random_string.rds_username.result}"
  key_id = "${aws_kms_key.sonarqube-parameters.key_id}"
}

resource "aws_ssm_parameter" "rds_password" {
  name   = "/${var.prefix}/rds-password"
  type   = "SecureString"
  value  = "${random_string.rds_password.result}"
  key_id = "${aws_kms_key.sonarqube-parameters.key_id}"
}
