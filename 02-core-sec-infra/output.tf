
output "FGTPublicIP" {
  value = module.infrastructure.FGTPublicIP
}

output "Username" {
  value = "admin"
}

output "Password" {
  value = module.infrastructure.Password
}

output "LoadBalancerPrivateIP" {
  value = module.infrastructure.LoadBalancerPrivateIP
}

output "CustomerVPC" {
  value = module.infrastructure.CustomerVPC
}

output "FGTVPC" {
  value = module.infrastructure.FGTVPC
}

output "customer_vpc_id" {
  value = module.infrastructure.customer_vpc_id
}
output "fwsshkey" {
  value = module.infrastructure.fwsshkey
}

output "csprivatesubnetaz2" {
  value = module.infrastructure.csprivatesubnetaz2
}

output "csprivatesubnetaz1" {
  value = module.infrastructure.csprivatesubnetaz1
}