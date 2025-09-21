output "bastion_host_ip" {
  value      = aws_instance.bastion_host.private_ip
  depends_on = [aws_instance.bastion_host]
}

output "bastion_host_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion_host.public_ip
  depends_on  = [aws_instance.bastion_host]
}