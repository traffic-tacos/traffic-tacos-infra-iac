output "bastion_host_ip" {
    value = aws_instance.bastion_host.private_ip
    depends_on = [ aws_instance.bastion_host]
}