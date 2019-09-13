provider "aws" {
  region = "eu-west-1"
  profile = "default"
}

variable "vpcid"{
  type = "string"
  default = "vpc-8d15e7eb"
}

variable "ami"{
  default = "ami-08935252a36e25f85"
}

variable "aws_subnets" {
  type    = "list"
  default = ["subnet-9cbfa3fb", "subnet-827d25d9"]
}

resource "aws_security_group" "devops_sg" {
  name        = "devops_sg"
  description = "sg for devops test"
  vpc_id      = "${var.vpcid}"
  
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "devops_key"
  public_key = "${file("/Users/aeghobor/.ssh/devops_test.pub")}"
}
  
locals {
  frontend-userdata = <<EOF
#!/bin/bash
yum -y update 
yum install -y nginx
curl --silent --location https://rpm.nodesource.com/setup_11.x | sudo bash -
sudo yum install -y nodejs nodejs-devel --enablerepo=nodesource
node -v
sudo yum install -y git
git clone https://github.com/eghos/devops_test.git 
cd devops_test/frontend
npm install
npm run build 
sudo cp nginx/default.conf /etc/nginx/conf.d/default.conf
sudo cp -R build /usr/share/nginx/html/build
sudo service nginx start
EOF
}

resource "aws_instance" "frontend" {
  ami           = "${var.ami}"
  instance_type = "t2.micro"
  key_name = "devops_key"
  vpc_security_group_ids = ["${aws_security_group.devops_sg.id}"]
  tags = {
    Name = "devops_frontend"
  }
  user_data_base64 = "${base64encode(local.frontend-userdata)}"
}

#SERVER

locals {
  server-userdata = <<EOF
#!/bin/bash
yum -y update 
curl --silent --location https://rpm.nodesource.com/setup_11.x | sudo bash -
sudo yum install -y nodejs nodejs-devel --enablerepo=nodesource
node -v
sudo yum install -y git
git clone https://github.com/eghos/devops_test.git 
cd devops_test/server
npm install
npm run start
EOF
}

resource "aws_instance" "server" {
  ami           = "${var.ami}"
  instance_type = "t2.micro"
  key_name = "devops_key"
  vpc_security_group_ids = ["${aws_security_group.devops_sg.id}"]
  tags = {
    Name = "devops_server"
  }
  user_data_base64 = "${base64encode(local.server-userdata)}"
}

# WORKER
  
locals {
  worker-userdata = <<EOF
#!/bin/bash
yum -y update 
curl --silent --location https://rpm.nodesource.com/setup_11.x | sudo bash -
sudo yum install -y nodejs nodejs-devel --enablerepo=nodesource
node -v
sudo yum install -y git
git clone https://github.com/eghos/devops_test.git 
cd devops_test/worker
npm install
npm run start
EOF
}

resource "aws_instance" "worker" {
  ami           = "${var.ami}"
  instance_type = "t2.micro"
  key_name = "devops_key"
  vpc_security_group_ids = ["${aws_security_group.devops_sg.id}"]
  tags = {
    Name = "devops_worker"
  }
  user_data_base64 = "${base64encode(local.worker-userdata)}"
}

#ALB

resource "aws_lb" "devops" {
  name               = "devops-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = ["${aws_security_group.devops_sg.id}"]
  subnets            = ["${var.aws_subnets[0]}","${var.aws_subnets[1]}"]
  
  enable_deletion_protection = false

  tags = {
    Environment = "devops_env"
  }
}

resource "aws_lb_listener" "devops" {
  load_balancer_arn = "${aws_lb.devops.arn}"
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.frontend.arn}"
  }
}

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = "${aws_lb_listener.devops.arn}"
  priority     = 200
  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.frontend.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/"]
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = "${aws_lb_listener.devops.arn}"
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.api.arn}"
  }

  condition {
    field  = "path-pattern"
    values = ["/api"]
  }
}

# health_check - TO BE ADDED

resource "aws_lb_listener_rule" "frontend_health_check" {
  listener_arn = "${aws_lb_listener.devops.arn}"

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "HEALTHY"
      status_code  = "200"
    }
    target_group_arn = "${aws_lb_target_group.frontend.arn}"
  }
  condition {
    field  = "path-pattern"
    values = ["/health"]
  }
}

  resource "aws_lb_listener_rule" "api_health_check" {
  listener_arn = "${aws_lb_listener.devops.arn}"

  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "HEALTHY"
      status_code  = "200"
    }
    target_group_arn = "${aws_lb_target_group.api.arn}"
  }
  condition {
    field  = "path-pattern"
    values = ["/health"]
  }
}

  resource "aws_lb_target_group" "frontend" {
  name     = "frontend"
  port     = 3000
  protocol = "HTTP"
  vpc_id  = "${var.vpcid}"
}

resource "aws_lb_target_group" "api" {
  name     = "api"
  port     = 5000
  protocol = "HTTP"
  vpc_id  = "${var.vpcid}"
}

resource "aws_lb_target_group_attachment" "frontend" {
  target_group_arn = "${aws_lb_target_group.frontend.arn}"
  target_id        = "${aws_instance.frontend.id}"
  port             = 3000
}

resource "aws_lb_target_group_attachment" "api" {
  target_group_arn = "${aws_lb_target_group.api.arn}"
  target_id        = "${aws_instance.server.id}"
  port             = 5000
}