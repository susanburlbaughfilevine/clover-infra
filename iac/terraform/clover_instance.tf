
locals {
  iam_instance_profile = "${var.envName}-CloverApp-InstanceProfile"
  key_name             = aws_key_pair.clover.key_name
}

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

resource "aws_security_group" "internal_alb_sg" {
  name        = "${var.envName}-clover-alb-internal"
  description = "Allow web traffic from ZPA"
  vpc_id      = data.aws_vpc.clover.id

  ingress {
    description = "Ingress HTTPS traffic from Filevine platform services CJIS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.17.80.0/21"]
  }

  ingress {
    description = "Ingress HTTP traffic from Filevine platform services CJIS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.17.80.0/21"]
  }

  ingress {
    description = "Ingress HTTP traffic from local VPC subnets"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.17.88.0/21"]
  }

  ingress {
    description = "Ingress HTTPS traffic from local VPC subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.17.88.0/21"]
  }

  egress {
    description = "Egress traffic from load balancer to filevine platofmr services VPC subnet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.17.80.0/21"]
  }

  egress {
    description = "Egress traffic from load balancer to filevine platform services VPC subnet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.17.80.0/21"]
  }

  egress {
    description = "Egress traffic from load balancer to DM-CJIS VPC subnet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["172.17.88.0/21"]
  }
  egress {
    description = "Egress traffic from load balancer to DM-CJIS VPC subnet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.17.88.0/21"]
  }
  tags = {
    Name = "${var.envName}-clover-alb-interal-sg"
  }
}

resource "aws_lb" "clover_alb_internal" {
  name               = "${var.envName}-clover-alb-internal"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb_sg.id]
  subnets            = data.aws_subnet_ids.public.ids
  ip_address_type    = "ipv4"
  tags = {
    Name = "${var.envName}-clover-alb-internal"
  }
}

resource "aws_lb_listener" "https_internal" {
  load_balancer_arn = aws_lb.clover_alb_internal.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-2019-08"
  certificate_arn   = aws_acm_certificate.frontend_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.clover_tg_internal.arn
  }
}

resource "aws_lb_listener" "http_internal" {
  load_balancer_arn = aws_lb.clover_alb_internal.arn
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
    path                = "/clover/"
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    matcher             = "302"
    port                = 80
  }

  tags = {
    Name       = "${var.envName}-clover-tg"
    managed_by = "Octopus via Terraform"
    env        = var.envName
  }

}

resource "aws_lb_target_group" "clover_tg_internal" {
  name     = "${var.envName}-front-web-internal"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.clover.id
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 7200
  }

  health_check {
    path                = "/clover/"
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    matcher             = "302"
    port                = 80
  }

  tags = {
    Name       = "${var.envName}-clover-internal-tg"
    managed_by = "Octopus via Terraform"
    env        = var.envName
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.clover_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-2019-08"
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

resource "aws_lb_target_group_attachment" "tg_attach" {
  target_group_arn = aws_lb_target_group.clover_tg.arn
  target_id        = aws_instance.clover.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attach_internal" {
  target_group_arn = aws_lb_target_group.clover_tg_internal.arn
  target_id        = aws_instance.clover.id
  port             = 80
}

resource "aws_instance" "clover" {
  ami           = data.aws_ami.windows.id
  instance_type = var.instance_type

  tags = {
    Name       = "${var.envName}-clover-0"
    managed_by = "terraform"
    env        = var.envName
  }

  vpc_security_group_ids = [
    aws_security_group.backend.id,
    aws_security_group.frontend.id,
    aws_security_group.techaccess.id,
    aws_security_group.dataaccess.id
  ]

  iam_instance_profile = local.iam_instance_profile
  subnet_id            = element(tolist(data.aws_subnet_ids.private.ids), 0)
  key_name             = local.key_name
  user_data = templatefile("${path.module}/userdata.ps1", {
    octopus_api_key            = var.octopus_api_key
    octopus_server_address     = var.octopus_server_address
    octopus_server_environment = var.octopus_server_environment
    octopus_space              = var.octopus_space
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
  lifecycle {
  # uncomment when ready for production
  #  prevent_destroy = true
  }
}

resource "aws_ebs_volume" "clover_instance_volume_1" {
  availability_zone = aws_instance.clover.availability_zone
  size              = 3200
  kms_key_id        = data.aws_kms_alias.backend.target_key_arn
  encrypted         = true

  tags = {
    Name = "${var.envName}-clover-volume-1"
  }
}

resource "aws_volume_attachment" "clover_volume_attach_1" {
  device_name = "xvdg"
  instance_id = aws_instance.clover.id
  volume_id   = aws_ebs_volume.clover_instance_volume_1.id
}
