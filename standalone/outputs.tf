output "sonarqube_URL" {
  value = "https://${aws_route53_record.sonarqube.fqdn}"
}
