#!/bin/bash
sudo yum update -y 
sudo amazon-linux-extras install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
newgrp docker
docker run -p 8080:80 nginx