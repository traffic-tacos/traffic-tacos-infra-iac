output "zone_id" {
  description = "The hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "zone_name" {
  description = "The hosted zone name"
  value       = aws_route53_zone.main.name
}

output "name_servers" {
  description = "List of name servers for the hosted zone"
  value       = aws_route53_zone.main.name_servers
}

output "api_record_name" {
  description = "FQDN of the API record"
  value       = try(aws_route53_record.api[0].fqdn, "")
}

output "www_record_name" {
  description = "FQDN of the WWW record"
  value       = try(aws_route53_record.www[0].fqdn, "")
}