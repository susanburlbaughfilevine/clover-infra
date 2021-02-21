resource "aws_security_group" "datastores" {
  name        = "${var.envName}-clover-DatastoresAccess"
  description = "Used to access the Datastores - managed via octopus"
  vpc_id      = data.aws_vpc.clover.id

  ingress {
    description     = "SQL Server"
    from_port       = 1433
    to_port         = 1433
    protocol        = "tcp"
    self            = true
    security_groups = [aws_security_group.frontend.id]
  }

  tags = {
    Name       = "${var.envName}-clover-DatastoresAccess"
    managed_by = "Octopus via Terraform"
  }

}

resource "aws_security_group" "frontend" {
  name        = "${var.envName}-clover-FrontEnd"
  description = "FrontEnd Systems of Clover - managed by octopus"
  vpc_id      = data.aws_vpc.clover.id

  tags = {
    Name       = "${var.envName}-clover-FrontEnd"
    managed_by = "Octopus via Terraform"
  }

  ingress {
    description     = "Clover"
    from_port       = 8083
    to_port         = 8083
    protocol        = "tcp"
    self            = true
    cidr_blocks = ["0.0.0.0/0"]
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
  name        = "${var.envName}-clover-Backend"
  description = "Backend Systems of CloverApp - managed via octopus"
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
    cidr_blocks = ["172.17.64.0/21", "172.17.80.0/21"]
  }

  tags = {
    Name       = "${var.envName}-clover-Backend"
    managed_by = "Octopus via Terraform"
  }

}
resource "aws_security_group" "build" {
  name        = "${var.envName}-clover-Build"
  description = "Access to shared entities in the Common for Builds etc"
  vpc_id      = data.aws_vpc.clover.id

  tags = {
    Name       = "${var.envName}-clover-Build"
    managed_by = "Octopus via Terraform"
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