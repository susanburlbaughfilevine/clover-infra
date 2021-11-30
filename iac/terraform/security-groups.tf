
resource "aws_security_group" "frontend" {
  name        = "${var.envName}-FrontEnd"
  description = "FrontEnd Systems of CloverDX - managed by octopus"
  vpc_id      = data.aws_vpc.clover.id

  tags = {
    Name       = "${var.envName}-FrontEnd"
    managed_by = "Octopus via Terraform"
  }

  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.internal_alb_sg.id, aws_security_group.backend.id]
  }

  ingress {
    description     = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.internal_alb_sg.id, aws_security_group.backend.id]
  }

  ingress {
    description = "Okta Advanced Server Access"
    from_port   = 4421
    to_port     = 4421
    protocol    = "tcp"
    cidr_blocks = ["172.17.64.0/21"]
  }

  ingress {
    description = "Filevine Prod Import DB Server"
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["172.31.23.143/32"]
  }

  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend" {
  name        = "${var.envName}-Backend"
  description = "Backend Systems of CloverDX - managed via octopus"
  vpc_id      = data.aws_vpc.clover.id

  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Filevine Prod Import DB Server"
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["172.31.23.143/32"]
  }

  ingress {
    description = "Okta Advanced Server Access"
    from_port   = 4421
    to_port     = 4421
    protocol    = "tcp"
    cidr_blocks = ["172.17.64.0/21"]
  }

  tags = {
    Name       = "${var.envName}-Backend"
    managed_by = "Octopus via Terraform"
  }

}

resource "aws_security_group" "dataaccess" {
  name        = "${var.envName}-DatastoresAccess"
  description = "Used to access the Datastores - managed via octopus"
  vpc_id      = data.aws_vpc.clover.id

  ingress {
    description     = "SQL Server"
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.frontend.id, aws_security_group.backend.id]
    cidr_blocks     = ["172.17.88.0/21"]
  }

  ingress {
    description     = "Redis Access"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.frontend.id, aws_security_group.backend.id]
  }

  ingress {
    description     = "ElasticSearch Access"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.frontend.id, aws_security_group.backend.id]
  }

  tags = {
    Name       = "${var.envName}-DatastoresAccess"
    managed_by = "Octopus via Terraform"
  }
}

resource "aws_security_group" "techaccess" {
  name        = "${var.envName}-TechAccess"
  description = "Tech Support and Build Access - managed by octopus"
  vpc_id      = data.aws_vpc.clover.id

  tags = {
    Name       = "${var.envName}-TechAccess"
    managed_by = "Octopus via Terraform"
  }

  ingress {
    description = "RDP from Tech Team"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from Tech Team"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["172.31.10.85/32", "172.17.64.0/21"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["172.31.10.85/32", "172.17.64.0/21"]
  }

  ingress {
    description = "Octopus"
    from_port   = 10933
    to_port     = 10935
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["172.31.10.85/32", "172.17.64.0/21"]
  }

  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

