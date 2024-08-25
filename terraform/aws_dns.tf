# Get the DNS zone
data "aws_route53_zone" "zone" {
  provider     = aws.route53
  name         = local.aws_config.dnsZone
  private_zone = false
}

# Add DNS for public and private IPs
resource "aws_route53_record" "ec2_public_dns" {
  provider = aws.route53
  for_each = { for k, v in local.aws_config.ec2Instances : k => v if v.publicIP }
  zone_id  = data.aws_route53_zone.zone.zone_id
  name     = each.key
  type     = "A"
  ttl      = "30"
  records  = [aws_instance.ec2s[each.key].public_ip]
}

resource "aws_route53_record" "ec2_private_dns" {
  provider = aws.route53
  for_each = local.aws_config.ec2Instances
  zone_id  = data.aws_route53_zone.zone.zone_id
  name     = each.value["publicIP"] ? "${each.key}-priv" : "${each.key}"
  type     = "A"
  ttl      = "30"
  records  = [aws_instance.ec2s[each.key].private_ip]
}

resource "aws_route53_record" "azure_vm_private_dns" {
  provider = aws.route53
  for_each = merge(local.azure_config.linuxVMs, local.azure_config.windowsVMs)
  zone_id  = data.aws_route53_zone.zone.zone_id
  name     = each.value["publicIP"] ? "${each.key}-priv" : "${each.key}"
  type     = "A"
  ttl      = "30"
  records  = [azurerm_network_interface.vminterfaces[each.key].private_ip_address]
}

resource "aws_route53_record" "azure_vm_public_dns" {
  provider = aws.route53
  for_each = { for k, v in merge(local.azure_config.linuxVMs, local.azure_config.windowsVMs) : k => v if v.publicIP }
  zone_id  = data.aws_route53_zone.zone.zone_id
  name     = each.key
  type     = "A"
  ttl      = "30"
  records  = [azurerm_public_ip.public_ip[each.key].ip_address]
}

resource "aws_route53_record" "rds_private_dns" {
  provider = aws.route53
  for_each = local.aws_config.rdsInstances
  zone_id  = data.aws_route53_zone.zone.zone_id
  name     = each.key
  type     = "CNAME"
  ttl      = "30"
  records  = [aws_db_instance.db_instances[each.key].address]
}

