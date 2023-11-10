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
              sudo apt-get install ca-certificates curl gnupg lsb-release -y
              sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
              sudo apt-get update
              sudo apt-get install docker-ce docker-ce-cli containerd.io -y
              sudo groupadd docker
              sudo usermod -aG docker $USER
              newgrp docker
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
              mkdir docker-compose-app
              cat <<'EOT' > docker-compose-app/docker-compose.yml
              version: "3.3"
              services:
                frontweb:
                  image: nicholasjackson/fake-service:vm-v0.7.7
                  environment:
                    LISTEN_ADDR: 0.0.0.0:9090
                    MESSAGE: "Hello World"
                    NAME: "frontweb"
                    SERVER_TYPE: "http"
                    CONSUL_SERVER: 0.0.0.0
                    CONSUL_DATACENTER: "az1"
                    CENTRAL_CONFIG_DIR: /central
                    SERVICE_ID: "frontweb-v1"
                  ports:
                  - "9090:9090"
              EOT
              cd docker-compose-app
              sudo docker-compose up -d
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