

resource "aws_instance" "myDemoInstance" {
  ami           = "ami-062df10d14676e201"
  key_name      = "First-linux-key-1"
  instance_type = "t2.micro"

  tags = {
    Name = "machine_from_terraform"
    app  = "frontend"
  }
}

#Creating the VPC
resource "aws_vpc" "demo_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Demo_VPC" 
}
}

#Creating the Subnet

resource "aws_subnet" "subnet_1a" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone= "ap-south-1a"
   map_public_ip_on_launch = true

  tags = {
    Name = "First-subnet_1a"
  }
}

resource "aws_subnet" "subnet_1b" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone= "ap-south-1b"
   map_public_ip_on_launch = true

  tags = {
    Name = "Second-subnet_1b"
  }
}

#Creating EC2 instance with Subnet

resource "aws_instance" "webapp-1" {
  ami           = "ami-062df10d14676e201"
  key_name      = "First-linux-key-1"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_1a.id
  vpc_security_group_ids = [aws_security_group.allow_port-80-22.id]
  tags = {
    Name = "webapp-1"
    app  = "frontend"
  }
}

  resource "aws_instance" "webapp-2" {
  ami           = "ami-062df10d14676e201"
  key_name      = "First-linux-key-1"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_1b.id
  vpc_security_group_ids = [aws_security_group.allow_port-80-22.id]
  tags = {
    Name = "webapp-2"
    app  = "frontend"
  }
}



#Creating Inbound and Outbound Security group

  resource "aws_security_group" "allow_port-80-22" {
  name        = "allow_port-80 and port-22"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.demo_vpc.id

  ingress {
    description      = "Allow port 22"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

   ingress {
    description      = "Allow port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_22-80"
  }
}

  #Creating Internet Gateway 
  resource "aws_internet_gateway" "Demo_IG_1" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "Demo_IG_1"
  }
}

#Creating RouteTable

  resource "aws_route_table" "webapp_RouteTable" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Demo_IG_1.id
  }

  tags = {
    Name = "webapp_RouteTable"
  }
}


# Creating Route Table Association 

  resource "aws_route_table_association" "webapp-RT-association-1A" {
  subnet_id      = aws_subnet.subnet_1a.id
  route_table_id = aws_route_table.webapp_RouteTable.id
}

  resource "aws_route_table_association" "webapp-RT-association-1B" {
  subnet_id      = aws_subnet.subnet_1b.id
  route_table_id = aws_route_table.webapp_RouteTable.id
}

 # Creating the target Group for Load Balancer
 
 resource "aws_lb_target_group" "webapp-LB-TargetGroup" {
  name     = "webapp-LB-TargetGroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo_vpc.id
}

# Attching Target group with Instance

resource "aws_lb_target_group_attachment" "webapp-LB-TargetGroup-Attachment-1" {
  target_group_arn = aws_lb_target_group.webapp-LB-TargetGroup.arn
  target_id        = aws_instance.webapp-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "webapp-LB-TargetGroup-Attachment-2" {
  target_group_arn = aws_lb_target_group.webapp-LB-TargetGroup.arn
  target_id        = aws_instance.webapp-2.id
  port             = 80
}

# Creating the  Load Balancer

resource "aws_lb" "webapp-LoadBalance" {
  name               = "webapp-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow-LB-80.id]
  subnets            = [aws_subnet.subnet_1a.id,aws_subnet.subnet_1b.id]

  #enable_deletion_protection = true
  tags = {
    Environment = "production"
  }
}

# Creating Security Group For Load Balance

resource "aws_security_group" "allow-LB-80" {
  name        = "allow_port-80"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.demo_vpc.id


   ingress {
    description      = "Allow port 80"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_LB_80"
  }
}


# Creating Load Balancer Listener 

resource "aws_lb_listener" "webapp-LoadBalancer-Listener" {
  load_balancer_arn = aws_lb.webapp-LoadBalance.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-LB-TargetGroup.arn
  }
}






