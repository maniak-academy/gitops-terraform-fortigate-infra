terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.1"
    }
    fortios = {
      source  = "fortinetdev/fortios"
      version = "1.18.0"
    }
  }
}

terraform {
  backend "s3" {
    encrypt        = true
    bucket         = "fgs3-om3j-terraform-state"
    key            = "fgs3-om3j-terraform-state"
    region         = "eu-west-1"
    dynamodb_table = "fgs3-om3j-terraform-state-lock-dynamo"
  }
}
provider "aws" {
  region = "eu-west-1"
}



provider "fortios" {
  hostname = module.infrastructure.FGTPublicIP
  token    = var.fortios_token
  insecure = "true"
}




module "infrastructure" {
  source = "./infrastructure"
}

module "core-fw-config" {
  source = "./core-fw-config"
  depends_on = [ module.infrastructure ]
}

module "apps" {
  source = "./apps"
  fwsshkey           = module.infrastructure.fwsshkey
  customer_vpc_id    = module.infrastructure.customer_vpc_id
  csprivatesubnetaz1 = module.infrastructure.csprivatesubnetaz1
  
  depends_on = [ module.core-fw-config ]

}