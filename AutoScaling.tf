
#Creating AWS autoscalling 
resource "aws_launch_template" "webapp-Launch-template" {
  name_prefix   = "webapp"
  image_id      = "ami-07a4130979e8e4d32"
  instance_type = "t2.micro"
  key_name      = "First-linux-key-1"
  vpc_security_group_ids = [aws_security_group.allow_port-80-22.id]
}

resource "aws_autoscaling_group" "webapp-ASG" {
  # availability_zones = ["ap-south-1a","ap-south-1b"]
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2
  vpc_zone_identifier = [aws_subnet.subnet_1a.id,aws_subnet.subnet_1b.id]

  launch_template {
    id      = aws_launch_template.webapp-Launch-template.id
    version = "$Latest"
  }
}

# creating target group for LB

resource "aws_lb_target_group" "webapp-LB-target-group-2" {
  name     = "webapp-LB-taget-group-2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo-vpc.id
  
}
