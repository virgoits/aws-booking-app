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

    iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm.name
  }

  # Basic startup script: installs a web server and shows a placeholder page
    user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y python3.11 python3.11-pip git

    cd /home/ec2-user
    git clone https://github.com/virgoits/aws-booking-app.git
    cd aws-booking-app/app

    python3.11 -m pip install flask pymysql

    export DB_HOST="${aws_db_instance.main.address}"
    export DB_USER="admin"
    export DB_PASSWORD="${var.db_password}"
    export DB_NAME="bookingapp"

    python3.11 app.py > /var/log/booking-app.log 2>&1 &
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

  # --- NEW: automatically refresh instances when the launch template changes ---
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 60
    }
  }

  tag {
    key                 = "Name"
    value               = "booking-app-asg-instance"
    propagate_at_launch = true
  }
}