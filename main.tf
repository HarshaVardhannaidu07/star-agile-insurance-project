resource "tls_private_key" "mykey" {
 algorithm = "RSA"
 rsa_bits  = 4096
}

resource "local_file" "pem_file" {
 content         = tls_private_key.mykey.private_key_pem
 filename        = "Project1Key.pem"
 file_permission = "400"
}

resource "aws_key_pair" "aws_key" {
 key_name   = "Project1Key"
 public_key = tls_private_key.mykey.public_key_openssh
}

resource "aws_vpc" "sl-vpc" {
 cidr_block = var.vpc_cidr
 tags = { Name = "sl-vpc" }
}

resource "aws_subnet" "subnet-1" {
 vpc_id                  = aws_vpc.sl-vpc.id
 cidr_block              = var.subnet_cidr
 map_public_ip_on_launch = true
 tags = { Name = "sl-subnet" }
}

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.sl-vpc.id
 tags = { Name = "sl-gw" }
}

resource "aws_route_table" "sl-route-table" {
 vpc_id = aws_vpc.sl-vpc.id
 tags = { Name = "sl-route-table" }
}

resource "aws_route" "sl-route" {
 route_table_id         = aws_route_table.sl-route-table.id
 destination_cidr_block = "0.0.0.0/0"
 gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "a" {
 subnet_id      = aws_subnet.subnet-1.id
 route_table_id = aws_route_table.sl-route-table.id
}

resource "aws_security_group" "sl-sg" {
 name   = "sg_rule"
 vpc_id = aws_vpc.sl-vpc.id

 dynamic "ingress" {
  for_each = var.sg_ports
  iterator = port
  content {
   from_port   = port.value
   to_port     = port.value
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
  }
 }

 egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_instance" "dev" {
 ami                    = var.ami
 instance_type          = var.instance_type
 key_name               = aws_key_pair.aws_key.key_name
 subnet_id              = aws_subnet.subnet-1.id
 vpc_security_group_ids = [aws_security_group.sl-sg.id]

 tags = { Name = "Project-Dev" }
}

resource "aws_instance" "test" {
 ami                    = var.ami
 instance_type          = var.instance_type
 key_name               = aws_key_pair.aws_key.key_name
 subnet_id              = aws_subnet.subnet-1.id
 vpc_security_group_ids = [aws_security_group.sl-sg.id]

 tags = { Name = "Project-Test" }
}


resource "aws_instance" "prod" {
 ami                    = var.ami
 instance_type          = var.instance_type
 key_name               = aws_key_pair.aws_key.key_name
 subnet_id              = aws_subnet.subnet-1.id
 vpc_security_group_ids = [aws_security_group.sl-sg.id]

 tags = { Name = "Project-Prod" }
}
