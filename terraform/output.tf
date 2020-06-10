### AWS connection data
output "current_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "current_user_arn" {
  value = data.aws_caller_identity.current.arn
}

output "current_region_name" {
  value = data.aws_region.current.name
}

output "kubectl_role_arn" {
  value = aws_iam_role.kubectl.arn
}

### Bastion data
output "ssh_private_key" {
  value = tls_private_key.main.private_key_pem
}

output "bastion_dns_name" {
  value = aws_instance.bastion.public_dns
}
