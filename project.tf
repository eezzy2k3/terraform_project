provider "aws" {
  region     = "us-east-1"
}

# create a vpc
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

}

# internet gateway to give internet to subnet
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "main"
  }
}

# route table to connect internet gateway to vpc and subnet
resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }



  tags = {
    Name = "myroutetable"
  }

}

#create 2 public subnet
resource "aws_subnet" "subnet" {
  for_each = var.subnet

  availability_zone_id = each.value["az"]
  cidr_block           = each.value["cidr"]
  vpc_id               = aws_vpc.vpc.id
    map_public_ip_on_launch = true


  tags = {
    Name = "${var.sb-name}-subnet-${each.key}"
  }
}

# security group to allow http and ssh
resource "aws_security_group" "sg" {
  name        = "allow_all"
  description = "Allow HTTP, HTTPS and SSH traffic via Terraform"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#route table association to associate subnet
resource "aws_route_table_association" "rta" {
  for_each       = aws_subnet.subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_alb" "alb" {
  name            = "alb"
  security_groups = ["${aws_security_group.sg.id}"]
  subnets         = [for subnet in aws_subnet.subnet : subnet.id]

}

#load balancer target group
resource "aws_lb_target_group" "target_group" {
  name     = "mytarget"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}
#attach target group to load balancer
resource "aws_lb_target_group_attachment" "atch" {
  count            = length(aws_instance.ec2_instance)
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.ec2_instance[count.index].id
  port             = 80
}

#create 3 ec2 instance
resource "aws_instance" "ec2_instance" {
  ami                    = var.ami_id
  count                  = var.number_of_instances
  instance_type          = var.instance_type
  key_name               = var.ami_key_pair_name
  associate_public_ip_address = true
  subnet_id              = values(aws_subnet.subnet)[0].id
  vpc_security_group_ids = [aws_security_group.sg.id]


}


#display all ec2 public ip
output "instance_public_ip" {

  description = "Public IP address of the EC2 instance"
  value       = [aws_instance.ec2_instance.*.public_ip]
}

#display load balancer dns
output "dns_name" {
  description = "The DNS name of the load balancer."
  value       = aws_alb.alb.dns_name
}

#route 53 records
data "aws_route53_zone" "myzone" {
  name         = "eezzy.com.ng"
  
}

#create alias record
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.myzone.zone_id
  name    ="www.terraform-test.${data.aws_route53_zone.myzone.name}"
  type    = "A"

  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}
