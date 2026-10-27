output "vpc_id" {
  description = "The ID of the dev VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the dev VPC"
  value       = module.vpc.vpc_cidr_block
}

