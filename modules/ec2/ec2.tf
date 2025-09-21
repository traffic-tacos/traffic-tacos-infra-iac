resource "aws_instance" "bastion_host" {
  ami                         = "ami-08c5f168115c8dd04"
  instance_type               = "t3.micro"
  subnet_id                   = var.public_subnet[0]
  associate_public_ip_address = true
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.bastion.id]

  tags = {
    Name = "${var.name}-bastion-host"
  }

}

data "aws_ssm_parameter" "whitelist_ips" {
  name = "/${var.name}/bastion/whitelist_ip"
}