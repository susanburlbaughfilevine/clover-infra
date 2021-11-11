

/// This references the primary Domain Name of the website.  This does NOT imply filevine.com.  It could be filevinedev.com etc.  
//  (Poor choice in resource names)
data "aws_route53_zone" "filevine" {
  provider     = aws.filevine
  name         = var.dns_domain
  private_zone = false
}

/// This references the short URL domain of the website.  This does NOT imply flvn.io.   (Poor Choice in resource names)
data "aws_route53_zone" "flvn" {
  provider     = aws.filevine
  name         = var.shorturl_dns_domain
  private_zone = false
}

locals {
  frontend_domain = lower("${var.subdomain}.${var.dns_domain}")
  alt_domain_names = [
    "*.${var.dns_domain}",
    "*.${var.shorturl_dns_domain}"
  ]
  zone_id = {
    (local.frontend_domain)     = data.aws_route53_zone.filevine.zone_id
    (local.alt_domain_names[0]) = data.aws_route53_zone.filevine.zone_id
    (local.alt_domain_names[1]) = data.aws_route53_zone.flvn.zone_id
  }
}

resource "aws_acm_certificate" "frontend_certificate" {
  domain_name       = local.frontend_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  subject_alternative_names = local.alt_domain_names

  tags = {
    Name = "${var.envName}-frontend-certificate"
  }
}

resource "aws_route53_record" "frontend_validate" {
  provider = aws.filevine
  for_each = {
    for dvo in aws_acm_certificate.frontend_certificate.domain_validation_options : dvo.domain_name => {
      name    = dvo.resource_record_name
      record  = dvo.resource_record_value
      type    = dvo.resource_record_type
      zone_id = local.zone_id[dvo.domain_name]
    }
  }
  name            = each.value.name
  records         = [each.value.record]
  type            = each.value.type
  zone_id         = each.value.zone_id
  allow_overwrite = true
  ttl             = 60
}

resource "aws_acm_certificate_validation" "frontend_validate" {
  certificate_arn         = aws_acm_certificate.frontend_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.frontend_validate : record.fqdn]
}

data "aws_route53_zone" "master" {
  provider = aws.filevine
  name     = var.dns_domain
}

resource "aws_route53_record" "clover_frontend_record" {
  provider = aws.filevine
  zone_id  = data.aws_route53_zone.master.id
  name     = "${var.subdomain}.${var.dns_domain}"
  type     = "A"

  alias {
    name                   = aws_lb.clover_alb.dns_name
    zone_id                = aws_lb.clover_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "import_internal_record" {
  provider = aws.filevine
  zone_id  = data.aws_route53_zone.master.id
  name     = "internal-${var.envName}-import.${var.dns_domain}"
  type     = "CNAME"
  ttl      = 300
  records  = ["${aws_instance.tools_instance.private_dns}"]
}

resource "aws_route53_record" "clover_internal_record" {
  provider = aws.filevine
  zone_id  = data.aws_route53_zone.master.id
  name     = "internal-clover-cjis.${var.dns_domain}"
  type     = "CNAME"
  ttl      = 300
  records  = ["${aws_lb.clover_alb_internal.dns_name}"]
}
