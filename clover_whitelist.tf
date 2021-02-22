resource "aws_security_group" "clover_whitelist" {
  name        = "${var.envName}-clover-whitelist"
  description = "Whitelist for CloverDX"
  vpc_id      = data.aws_vpc.clover.id

  tags = {
    Name       = "${var.envName}-Clover-DX"
    managed_by = "Octopus via Terraform"
  }

  ingress {
    description = "Austin Patterson Home"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["76.192.9.181/32"]
  }

  ingress {
    description = "Josh Mortensen"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["104.216.240.98/32"]
  }

  ingress {
    description = "Bhavin Tailor"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = true
    cidr_blocks = ["45.89.173.162/32"]
  }

  egress {
    description = "Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}