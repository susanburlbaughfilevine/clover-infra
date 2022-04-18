# Once ready for apply, be sure to check for conflicts between security groups in security-groups.tf and security_groups.tf

resource "aws_security_group" "internal_alb_sg" {
  name        = "${var.envName}-clover-alb-internal"
  description = "Allow web traffic from ZPA"
  vpc_id      = data.aws_vpc.clover.id
  tags = {
    Name = "${var.envName}-clover-alb-interal-sg"
  }
}

resource "aws_security_group" "cloverdx_to_worker_ssh" {
  name        = "${var.envName}-clover-worker-ssh"
  description = "Allow SSH traffic from CloverDX Server to worker"
  vpc_id      = data.aws_vpc.clover.id
  tags = {
    Name = "${var.envName}-clover-worker-ssh"
  }
}

resource "aws_security_group" "cloverdx" {
  name   = "${var.envName}-cloverdx"
  vpc_id = data.aws_vpc.clover.id

  tags = {
    Name       = "${var.envName}-cloverdx"
    managed_by = "Octopus via Terraform"
  }
  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.internal_alb_sg.id]
  }

  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.internal_alb_sg.id]
    cidr_blocks     = [var.zpa_subnet_cidr]
  }


  ingress {
    description = "Okta Advanced Server Access"
    from_port   = 4421
    to_port     = 4421
    protocol    = "tcp"
    cidr_blocks = ["172.17.64.0/21"]
  }
  ingress {
    description     = "Filevine Prod Import DB Server"
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    self            = true
    cidr_blocks     = ["172.31.23.143/32", var.zpa_subnet_cidr]
    security_groups = [aws_security_group.worker_dbaccess.id]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["172.17.64.0/21", "172.31.10.85/32"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["172.17.64.0/21", "172.31.10.85/32"]
  }

  ingress {
    description = "Octopus"
    from_port   = 10933
    to_port     = 10935
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["172.31.10.85/32", "172.17.64.0/21"]
  }

  ingress {
    description     = "SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.cloverdx_to_worker_ssh.id]
  }

  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "dataaccess" {
  name        = "${var.envName}-DatabaseAccess"
  description = "Used to access the Database - managed via octopus"
  vpc_id      = data.aws_vpc.clover.id

  ingress {
    description = "Database Server"
    from_port   = local.db_options[var.rds_engine].port
    to_port     = local.db_options[var.rds_engine].port
    protocol    = "tcp"
    self        = true
    cidr_blocks = [var.zpa_subnet_cidr]
  }

  tags = {
    Name       = "${var.envName}-DatabaseAccess"
    managed_by = "Octopus via Terraform"
  }
}

resource "aws_security_group" "worker_dbaccess" {
  name        = "${var.envName}-CloverWorker-DatabaseAccess"
  description = "CloverDX to worker node database access"
  vpc_id      = data.aws_vpc.clover.id

  tags = {
    Name       = "${var.envName}-CloverWorker-DatabaseAccess"
    managed_by = "Octopus via Terraform"
  }
}