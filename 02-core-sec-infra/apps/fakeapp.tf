variable "csprivatesubnetaz2" {

}

resource "aws_instance" "fakeapp_ec2" {
  ami             = "ami-0694d931cee176e7d" # Replace with the latest Ubuntu 20.04 AMI in your region
  instance_type   = "t2.micro"
  subnet_id       = var.csprivatesubnetaz2
  key_name        = var.fwsshkey
  associate_public_ip_address = true  # This line is added to associate a public IP
  vpc_security_group_ids      = [aws_security_group.fakeapp_sg.id] # Attach the security group

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              sudo apt-get update
              sudo apt-get install -y docker-ce
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker run --rm -d -p 80:80 yeasy/simple-web:latest
              EOF

  tags = {
    Name = "fakeappServer"
  }
}

resource "aws_security_group" "fakeapp_sg" {
  name        = "fakeapp_sg"
  description = "Allow inbound traffic on port 80 and all outbound traffic"
  vpc_id      = var.customer_vpc_id  # Replace this with your VPC ID if needed

  ingress {
    description      = "HTTP"
    from_port        = 9090
    to_port          = 9090
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] # Allows traffic from any IP address. Narrow this down as necessary for your use case.
  }
  ingress {
    description      = "ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] # Allows traffic from any IP address. Narrow this down as necessary for your use case.
  }
  egress {
    description      = "All traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # Allows all traffic
    cidr_blocks      = ["0.0.0.0/0"] # Allows traffic to any IP address
  }

  tags = {
    Name = "fakeapp_sg"
  }
}


module "fortios_firewall_config" {
  source  = "sebbycorp/apppolicy/fortigate"
  version = "1.0.3"
  vdomparam             = "FG-traffic"
  address_name          = "fakeapp_address"
  associated_interface  = "awsgeneve"
  action                = "accept"
  instance_ip           = aws_instance.fakeapp_ec2.private_ip
  policy_name           = "fakeapp_address_policy"
  interface_name        = "awsgeneve"
  services              = ["HTTP"] 
  nat                   = "disable" 
  logtraffic            = "all" 
  ssl_ssh_profile       = "no-inspection"
}