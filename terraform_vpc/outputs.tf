output "vpc_id" {
  value = module.vpc.vpc_id
}
output "public_subnets" {
  value = module.vpc.public_subnets
}
output "private_subnets" {
  value = module.vpc.private_subnets
}
output "nat_public_ip" {
  value = module.vpc.nat_public_ips
}