# --- The Load Balancer itself ---
resource "aws_lb" "app" {
  name               = "booking-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "booking-app-alb"
  }
}

# --- Target Group: the pool of EC2 instances the ALB sends traffic to ---
resource "aws_lb_target_group" "app" {
  name     = "booking-app-tg-v2"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
    timeout             = 5
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "booking-app-tg"
  }
}

# --- Listener: tells the ALB "when traffic hits port 80, send it to the target group" ---
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}