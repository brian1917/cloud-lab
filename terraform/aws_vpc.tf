// Create 1 VPC for every entry in the config file
resource "aws_vpc" "vpcs" {
  for_each             = local.aws_config.vpcs
  cidr_block           = each.value["cidrBlock"]
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = each.key
  }
}

// Create subnets based on VPC configs
resource "aws_subnet" "subnets" {
  for_each = {
    for subnet in local.vpc_subnets : "${subnet.vpc_name}.${subnet.subnet_key}" => subnet
  }
  vpc_id                  = each.value.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.public
  tags = {
    Name = each.key
  }
}

// Create the SSH key pair
resource "aws_key_pair" "auth" {
  for_each   = local.aws_config.vpcs
  key_name   = each.key
  public_key = file("${local.aws_config.sshKey}.pub")
}

# // Create 1 s3 bucket for VPC flow logs
# resource "aws_s3_bucket" "flow_logs" {
#   bucket        = "terraformvpcflowlogs"
#   force_destroy = true
# }

// Enable VPC flow logging for all VPCs
resource "aws_flow_log" "vpc_flow_log" {
  for_each = { for k, v in local.aws_config.vpcs : k => v if v.logFlows }
  log_destination      = local.aws_config.s3FlowLogArn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpcs[each.key].id
}