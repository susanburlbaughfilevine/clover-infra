
resource "aws_security_group" "tech" {
  name        = "${var.envName}-TechAccess"
  description = "Tech Support Access into these environments"
  vpc_id      = data.aws_vpc.filevine.id

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

}
