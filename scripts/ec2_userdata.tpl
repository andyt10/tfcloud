#!/bin/bash
sudo su
yum update -y
yum install -y httpd.x86_64
systemctl start httpd.service
systemctl enable httpd.service
echo "Hello Terraform study group from $(hostname -f)" > /var/www/html/index.html