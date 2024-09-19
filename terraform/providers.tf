provider "aws" {
  region  = local.aws_config.region
  profile = "${terraform.workspace}"
}

provider "aws" {
  alias   = "route53"
  profile = local.aws_config.route53AWSProfile
  region  = local.aws_config.region
}

provider "azurerm" {
  features {}
}
