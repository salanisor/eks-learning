output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

# Uncomment in Phase 6 alongside the endpoint resources
# output "s3_endpoint_id" {
#   description = "S3 VPC endpoint ID"
#   value       = aws_vpc_endpoint.s3.id
# }