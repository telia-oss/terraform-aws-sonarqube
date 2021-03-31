output "parameters_key_arn" {
  description = "The arn of the key used to encrypt the parameters"
  value       = aws_kms_key.sonarqube-parameters.arn
}

output "parameters_key_alias" {
  description = "The alias of the key used to encrypt the parameters"
  value       = aws_kms_alias.key-alias.name
}
