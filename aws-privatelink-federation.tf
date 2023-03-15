data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.customer_vpc_id]
  }
  tags = {
    Tier = "Private"
  }
}

locals {
  bootstrap = confluent_kafka_cluster.basic.bootstrap_endpoint
  hosted_zone = length(regexall(".glb", local.bootstrap)) > 0 ? replace(regex("^[^.]+-([0-9a-zA-Z]+[.].*):[0-9]+$", local.bootstrap)[0], "glb.", "") : regex("[.]([0-9a-zA-Z]+[.].*):[0-9]+$", local.bootstrap)[0]
  privatelink_service_name = confluent_network.aws-private-link.aws[0].private_link_endpoint_service
  bootstrap_prefix = split(".", local.bootstrap)[0]
  endpoint_prefix = split(".", aws_vpc_endpoint.privatelink.dns_entry[0]["dns_name"])[0]
  subnets_to_privatelink = {
    "aps1-az1" = "subnet-0c372435803c847b1",
    "aps1-az3" = "subnet-02a86967c1401972f",
    "aps1-az2" = "subnet-04f5b2efc96d6eda5"
    }
}

data "aws_vpc" "privatelink" {
  id = var.customer_vpc_id
}

data "aws_availability_zone" "privatelink" {
  for_each = local.subnets_to_privatelink
  zone_id = each.key
}

resource "aws_security_group" "privatelink" {
  # Ensure that SG is unique, so that this module can be used multiple times within a single VPC
  name = "ccloud-privatelink_${local.bootstrap_prefix}_${var.customer_vpc_id}"
  description = "Confluent Cloud Private Link minimal security group for ${local.bootstrap} in ${var.customer_vpc_id}"
  vpc_id = data.aws_vpc.privatelink.id

  ingress {
    # only necessary if redirect support from http/https is desired
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  ingress {
    from_port = 9092
    to_port = 9092
    protocol = "tcp"
    cidr_blocks = [data.aws_vpc.privatelink.cidr_block]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint" "privatelink" {
  vpc_id = data.aws_vpc.privatelink.id
  service_name = local.privatelink_service_name
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.privatelink.id,
  ]

  subnet_ids = [for zone, subnet_id in local.subnets_to_privatelink: subnet_id]
  private_dns_enabled = false
}

resource "aws_route53_zone" "privatelink" {
  name = local.hosted_zone

  vpc {
    vpc_id = data.aws_vpc.privatelink.id
  }
}

resource "aws_route53_record" "privatelink" {
  count = length(local.subnets_to_privatelink) == 1 ? 0 : 1
  zone_id = aws_route53_zone.privatelink.zone_id
  name = "*.${aws_route53_zone.privatelink.name}"
  type = "CNAME"
  ttl  = "60"
  records = [
    aws_vpc_endpoint.privatelink.dns_entry[0]["dns_name"]
  ]
}

resource "aws_route53_record" "privatelink-zonal" {
  for_each = local.subnets_to_privatelink

  zone_id = aws_route53_zone.privatelink.zone_id
  name = length(local.subnets_to_privatelink) == 1 ? "*" : "*.${each.key}"
  type = "CNAME"
  ttl  = "60"
  records = [
    format("%s-%s%s",
      local.endpoint_prefix,
      data.aws_availability_zone.privatelink[each.key].name,
      replace(aws_vpc_endpoint.privatelink.dns_entry[0]["dns_name"], local.endpoint_prefix, "")
    )
  ]
}