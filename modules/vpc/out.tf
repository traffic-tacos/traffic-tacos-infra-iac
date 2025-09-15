output "vpc_id" {
    value = aws_vpc.vpc.id
}

output "public_subnet" {
    value = [for s in aws_subnet.public: s.id]
}

output "app_subnet" {
    value = [for s in aws_subnet.private_app : s.id]
}

output "db_subnet" {
    value = [for s in aws_subnet.private_db : s.id]
}

output "vpc_cidr" {
    value = aws_vpc.vpc.cidr_block
}