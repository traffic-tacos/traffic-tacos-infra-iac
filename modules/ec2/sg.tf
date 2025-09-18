resource "aws_security_group" "bastion" {
    name = "${var.name}-sg-bastion"
    vpc_id = var.vpc_id

    egress {
        from_port = 0
        protocol = "-1"
        to_port = 0
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
      "Name" = "${var.name}-sg-bastion"
    }
}

resource "aws_security_group_rule" "allowssh" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = [for ip in split(",", data.aws_ssm_parameter.whitelist_ips.value) : "${ip}/32"]
    security_group_id = aws_security_group.bastion.id 
}

resource "aws_security_group_rule" "allowGithub" {
    type = "ingress"
    from_port = "4141"
    to_port = "4141"
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.bastion.id 
}


resource "aws_security_group_rule" "allowtest" {
    type = "ingress"
    from_port = "4142"
    to_port = "4142"
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.bastion.id 
}
