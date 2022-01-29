variable region {type=string}

provider "aws" {
  region = substr(var.region,0,9)
  access_key = YOUR_ACCESS_KEY
  secret_key = YOUR_SECRET_KEY
}



resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"

   tags = {
    Name = "production"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

}


resource "aws_route_table" "prod-rt" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "production"
  }
}





resource "aws_subnet" "prod-subnet" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.region

  tags = {
    Name = "production"
  }

 }

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prod-subnet.id
  route_table_id = aws_route_table.prod-rt.id
}


resource "aws_security_group" "allow_n8n" {
  name        = "allow_web_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] 
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] 
  }


  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp" 
    cidr_blocks      = ["0.0.0.0/0"] 
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_n8n"
  }
}

resource "aws_network_interface" "n8n-nic" {
  subnet_id       = aws_subnet.prod-subnet.id
  private_ips     = ["10.0.1.55"]
  security_groups = [aws_security_group.allow_n8n.id]


}
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.n8n-nic.id
  associate_with_private_ip = "10.0.1.55"
  depends_on = [aws_internet_gateway.gw, aws_instance.n8n-instance]

}


variable "n8n_username" {}
variable "n8n_password" {
  type= string
  sensitive = true
  description = "Please input n8n password"
}


resource "aws_instance" "n8n-instance" {
  ami           = "ami-0e472ba40eb589f49"
  instance_type = "t2.micro"
  availability_zone = var.region
  key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.n8n-nic.id

   
  }
   user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install docker.io -y
                sudo service docker start
                sudo systemctl enable docker
                sudo usermod -a -G docker ubuntu

                sudo docker run -it --rm \
                        --name n8n \
                        -p 80:5678 \
                        -e N8N_BASIC_AUTH_ACTIVE=true \
                        -e N8N_BASIC_AUTH_USER=${var.n8n_username} \
                        -e N8N_BASIC_AUTH_PASSWORD=${var.n8n_password} \
                        -v ~/.n8n:/home/node/.n8n \
                        -d n8nio/n8n
                EOF
    tags = {
      Name=  "n8n"
    }


}

output "n8n_public_ip" {
 value = aws_eip.one.public_ip
}




