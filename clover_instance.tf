resource "aws_lb" "clover_alb" {
  name               = "${var.envName}-clover-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.clover_whitelist.id]
  subnets            = data.aws_subnet_ids.public.ids
  ip_address_type    = "ipv4"
  tags = {
    Name = "${var.envName}-clover-alb"
  }
}

resource "aws_lb_target_group" "clover_tg" {
  name     = "${var.envName}-front-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.clover.id
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 7200
  }

  health_check {
    path                = "/clover/api/rest/v1/docs.html"
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    matcher             = "200"
    port                = 80
  }

  tags = {
    Name       = "${var.envName}-clover-tg"
    managed_by = "Octopus via Terraform"
    env        = var.envName
  }

}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.clover_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.frontend_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.clover_tg.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.clover_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.clover_tg.arn
  target_id        = aws_instance.clover.id
  port             = 80
}

resource "aws_instance" "clover" {
  ami           = data.aws_ami.windows.id
  instance_type = var.instance_type

  tags = {
    Name       = "${var.envName}-clover"
    managed_by = "terraform"
    env        = var.envName
  }

  vpc_security_group_ids = [
    data.aws_security_group.backend.id,
    data.aws_security_group.frontend.id,
    data.aws_security_group.build.id,
    data.aws_security_group.techaccess.id,
    data.aws_security_group.dataaccess.id
  ]

  iam_instance_profile = "${var.envName}-CloverApp-InstanceProfile"
  subnet_id            = element(tolist(data.aws_subnet_ids.private.ids), 0)
  key_name             = "dedicated-shards"
  user_data = templatefile("${path.module}/templates/userdata.ps1", {

    octopus_api_key            = var.octopus_api_key
    octopus_server_address     = var.octopus_server_address
    octopus_space              = var.octopus_space
    octopus_server_environment = var.octopus_server_environment
    octopus_tenant             = var.octopus_tenant
    server_roles               = "clover-server"
    scaleft_config             = file("${path.root}/sftd.yaml")
  })
  monitoring = false

  root_block_device {
    volume_size = 200
    encrypted   = true
    kms_key_id  = data.aws_kms_alias.backend.target_key_arn
  }
}