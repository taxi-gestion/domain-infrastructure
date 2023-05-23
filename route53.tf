resource "aws_route53_delegation_set" "domain_delegation_set" {
  reference_name = "${var.project} name server delegation set"
}


resource "aws_route53domains_registered_domain" "registered_domain" {
  domain_name = var.domain_name

  dynamic "name_server" {
    for_each = aws_route53_delegation_set.domain_delegation_set.name_servers
    content {
      name = name_server.value
    }
  }

  auto_renew    = true
  transfer_lock = false

  tags = local.tags
}

resource "aws_route53_zone" "hosting_zone" {
  name              = var.domain_name
  delegation_set_id = aws_route53_delegation_set.domain_delegation_set.id
  tags              = local.tags

  depends_on = [aws_route53domains_registered_domain.registered_domain]
}

resource "aws_route53_record" "main_name_servers_record" {
  name            = aws_route53_zone.hosting_zone.name
  allow_overwrite = true
  ttl             = 30
  type            = "NS"
  zone_id         = aws_route53_zone.hosting_zone.zone_id
  records         = aws_route53_zone.hosting_zone.name_servers

  depends_on = [aws_route53_zone.hosting_zone]
}

resource "aws_route53_record" "validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.acm_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.hosting_zone.zone_id
}
