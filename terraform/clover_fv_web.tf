

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

data "aws_route53_zone" "master" {
  provider = aws.filevine
  name     = var.dns_domain
}

resource "aws_route53_record" "import_internal_record" {
  provider = aws.filevine
  zone_id  = data.aws_route53_zone.master.id
  name     = "internal-${var.envName}-import.${var.dns_domain}"
  type     = "CNAME"
  ttl      = 300
  records  = [aws_instance.clover.private_dns]
}

resource "aws_route53_record" "clover_internal_record" {
  provider = aws.filevine
  zone_id  = data.aws_route53_zone.master.id
  name     = "clover-${var.envName}.${var.dns_domain}"
  type     = "CNAME"
  ttl      = 300
  records  = [aws_lb.clover_alb_internal.dns_name]
}
