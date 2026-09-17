# --- Subnet group: tells RDS which subnets it's allowed to use ---
resource "aws_db_subnet_group" "main" {
  name       = "booking-app-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name = "booking-app-db-subnet-group"
  }
}

# --- The RDS instance itself (Multi-AZ) ---
resource "aws_db_instance" "main" {
  identifier     = "booking-app-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "bookingapp"
  username = "admin"
  password = var.db_password  # we'll define this as a variable next, never hardcode it

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true  # fine for a demo/portfolio project; you'd set this to false for real client data

  tags = {
    Name = "booking-app-db"
  }
}