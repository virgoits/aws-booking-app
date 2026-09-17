# --- Get the latest Amazon Linux 2023 AMI automatically ---
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# --- Launch Template: the "blueprint" for each EC2 instance ---
resource "aws_launch_template" "app" {
  name_prefix   = "booking-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # Basic startup script: installs a web server and shows a placeholder page
  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Booking App - Server: $(hostname)</h1>" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "booking-app-instance"
    }
  }
}

# --- Auto Scaling Group: keeps the right number of instances running, across both AZs ---
resource "aws_autoscaling_group" "app" {
  name                = "booking-app-asg"
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  min_size            = 2
  max_size            = 4
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app.arn]

  tag {
    key                 = "Name"
    value               = "booking-app-asg-instance"
    propagate_at_launch = true
  }
}