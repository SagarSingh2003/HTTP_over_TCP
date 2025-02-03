provider "aws" {
 region = "ap-south-1"
}

terraform {
 backend "s3" {
        bucket          = "aws-s3-bucket-terraform-state"
        key             = "home/ubuntu/demo/statefile.tfstate"
        region          = "ap-south-1"
        encrypt         = true
        dynamodb_table = "aws-automation-terraform"
  }
}


resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = "vpc-0fb4270b3f594463a"

  # Allow inbound HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTPS traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb_target_group" "tg" {
  name     = "my-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "vpc-0fb4270b3f594463a"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = ["subnet-0d8b85a88c2d1e278" , "subnet-030ab1279adfa01c8"]

  enable_deletion_protection = false

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.test.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}


resource "aws_security_group_rule" "allow_port_3000" {
  type              = "ingress"
  from_port        = 3000
  to_port          = 3000
  protocol         = "tcp"
  security_group_id = "sg-0f1fdc139381614ee" 
  cidr_blocks      = ["0.0.0.0/0"] 
}

resource "aws_launch_template" "template"{

  name_prefix = "test"
  image_id    = "ami-023a307f3d27ea427"
  instance_type = "t2.micro"
  network_interfaces {
        security_groups = ["sg-0f1fdc139381614ee"]
  } 

  user_data = base64encode(file("user-data.sh")) # Launch Templates require user_data to be base64 encoded

  key_name = "outcook-backend"

  lifecycle {
    create_before_destroy = true
  }

}



resource "aws_autoscaling_group" "autoscale" {

   name  = "test-autoscaling-group"
   desired_capacity = 2
   max_size = 6
   min_size = 1
   health_check_type = "EC2"
   termination_policies = ["AllocationStrategy"]
   vpc_zone_identifier   = ["subnet-0d8b85a88c2d1e278"]

  target_group_arns = [aws_lb_target_group.tg.arn]

   launch_template{
        id = aws_launch_template.template.id
        version = "$Latest"
   }

   lifecycle {

    ignore_changes = [desired_capacity]

   }
}


resource "aws_autoscaling_policy" "scale_down" {

  name                   = "test_scale_down"

  autoscaling_group_name = aws_autoscaling_group.autoscale.name

  adjustment_type        = "ChangeInCapacity"

  scaling_adjustment     = -1

  cooldown               = 120

}



resource "aws_cloudwatch_metric_alarm" "scale_down" {

  alarm_description   = "Monitors CPU utilization"

  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  alarm_name          = "test_scale_down"

  comparison_operator = "LessThanOrEqualToThreshold"

  namespace           = "AWS/EC2"

  metric_name         = "CPUUtilization"

  threshold           = "25"

  evaluation_periods  = "5"

  period              = "30"

  statistic           = "Average"



  dimensions = {

    AutoScalingGroupName = aws_autoscaling_group.autoscale.name

  }

}

resource "aws_autoscaling_policy" "scale_up" {

  name                   = "test_scale_up"

  autoscaling_group_name = aws_autoscaling_group.autoscale.name

  adjustment_type        = "ChangeInCapacity"

  scaling_adjustment     = 1

  cooldown               = 120

}



resource "aws_cloudwatch_metric_alarm" "scale_up" {

  alarm_description   = "Monitors CPU utilization"

  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  alarm_name          = "test_scale_up"

  comparison_operator = "GreaterThanOrEqualToThreshold"

  namespace           = "AWS/EC2"

  metric_name         = "CPUUtilization"

  threshold           = "75"

  evaluation_periods  = "5"

  period              = "30"

  statistic           = "Average"



  dimensions = {

    AutoScalingGroupName = aws_autoscaling_group.autoscale.name

  }

}




