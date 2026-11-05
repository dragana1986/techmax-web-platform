output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets, in the same order as the availability zones"
  value       = module.vpc.public_subnet_ids
}

output "public_subnet_cidrs" {
  description = "The CIDR blocks of the public subnets, in the same order as the availability zones"
  value       = module.vpc.public_subnet_cidrs
}

output "private_app_subnet_ids" {
  description = "The IDs of the private application subnets, in the same order as the availability zones"
  value       = module.vpc.private_app_subnet_ids
}

output "private_app_subnet_cidrs" {
  description = "The CIDR blocks of the private application subnets, in the same order as the availability zones"
  value       = module.vpc.private_app_subnet_cidrs
}

output "internet_gateway_id" {
  description = "The ID of the internet gateway, or null when the VPC has no public subnets"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_public_ips" {
  description = "The public IP addresses of the NAT gateways. Outbound traffic from the private subnets uses these addresses, so partners add them to their allow-lists"
  value       = module.vpc.nat_gateway_public_ips
}

output "nat_gateway_ids" {
  description = "The IDs of the NAT gateways, used for CloudWatch alarms on NAT gateway metrics"
  value       = module.vpc.nat_gateway_ids
}

output "public_route_table_id" {
  description = "The ID of the public route table, or null when the VPC has no public subnets. Used to attach VPC gateway endpoints"
  value       = module.vpc.public_route_table_id
}

output "private_app_route_table_ids" {
  description = "The IDs of the private application route tables, in the same order as the availability zones. Used to attach VPC gateway endpoints"
  value       = module.vpc.private_app_route_table_ids
}
