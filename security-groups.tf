# --- Security Group for the ALB (public-facing) ---
resource "aws_security_group" "alb" {
  name        = "booking-app-alb-sg"
  description = "Allow HTTP/HTTPS from the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "booking-app-alb-sg"
  }
}

# --- Security Group for EC2 instances (only reachable from the ALB) ---
resource "aws_security_group" "ec2" {
  name        = "booking-app-ec2-sg"
  description = "Allow traffic only from the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App traffic from ALB only"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "booking-app-ec2-sg"
  }
}
# --- Security Group for RDS (only reachable from EC2 instances) ---
resource "aws_security_group" "rds" {
  name        = "booking-app-rds-sg"
  description = "Allow traffic only from EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from EC2 only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "booking-app-rds-sg"
  }
}