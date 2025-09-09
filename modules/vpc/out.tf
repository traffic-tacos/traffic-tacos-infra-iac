output "vpc_id" {
    value = aws_vpc.vpc.id
}

output "public_subnet" {
    value = aws_subnet.public[*].id
}

output "app_subnet" {
    value = aws_subnet.private_app[*].id
}

output "db_subnet" {
    value = aws_subnet.private_db[*].id
}

output "vpc_cidr" {
    value = aws_vpc.vpc.cidr_block
}