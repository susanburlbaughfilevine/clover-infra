
resource "aws_route53_record" "outgoingemail-1" {
  provider = aws.filevine
  zone_id  = data.aws_route53_zone.master.id
  name     = "mandrill._domainkey.${var.subdomain}.${var.dns_domain}"
  type     = "TXT"
  ttl      = 600

  records = [
    "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCrLHiExVd55zd/IQ/J/mRwSRMAocV/hMB3jXwaHH36d9NaVynQFYV8NaWi69c1veUtRzGt7yAioXqLj7Z4TeEUoOLgrKsn8YnckGs9i3B3tVFB+Ch/4mPhXWiNfNdynHWBcPcbJ8kjEQ2U8y78dHZj1YeRXXVvWob2OaKynO8/lQIDAQAB;"
  ]
}

resource "aws_route53_record" "outgoingemail-2" {
  provider = aws.filevine
  zone_id  = data.aws_route53_zone.master.id
  name     = "${var.subdomain}.${var.dns_domain}"
  type     = "TXT"
  ttl      = 600

  records = [
    "v=spf1 include:spf.mandrillapp.com ?all"
  ]
}
