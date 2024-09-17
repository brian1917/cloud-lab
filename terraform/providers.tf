provider "aws" {
  region  = local.aws_config.region
  profile = "${terraform.workspace}"
}

#provider "aws" {
#  alias   = "route53"
#  profile = "demosales"
#  region  = local.aws_config.region
#}


provider "aws" {
  alias   = "personal"
  profile = "personal"
  region  = local.aws_config.region
}

provider "azurerm" {
  features {}
}
