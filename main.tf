provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"] # Debian's AWS account ID
  filter {
    name   = "name"
    values = ["debian-*-amd64-*"]
  }
}

resource "aws_security_group" "web_sg" {
  name_prefix = "web-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 52020
    to_port     = 52020
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

resource "aws_instance" "web_server" {
  ami           = data.aws_ami.debian.id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_sg.name]

  tags = {
    Name = "web-server"
  }

  provisioner "file" {
    source       = "index.html"
    destination  = "/home/jason/index.html"
  }

  provisioner "file" {
    source      = "minesweeper.js"
    destination = "/home/jason/minesweeper.js"
  }

  provisioner "file" {
    source      = "minesweeper"
    destination = "/home/jason/minesweeper"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx nodejs npm

              # Disable root and password login
              sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
              sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

              # Create user 'jason' with sudo rights
              useradd -m -s /bin/bash jason
              echo 'jason ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

              # Set up SSH for user 'jason'
              mkdir -p /home/jason/.ssh
              chown jason:jason /home/jason/.ssh
              chmod 700 /home/jason/.ssh

              # Add your public key to authorized_keys
              echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9GZeoVJvQLCCH4xDySbU2i5i5vEL/+vwofAWdvGlmmQykBOYkNKiEOHgLXWgCO5FO7b+lAIDvNBsyrIvL3NLclT+3dDZyxfkslvvIlJiCTUgYAMeIlVoOUO8YJi1x4axxbZNRFEu5Lh4J+R+lUxfc/CH+PxCs2lR7rooyU+N6h/qtjer2YCu6fr82c5OuGqmJaalVD2fe4gpk33wxWMNfql2p+I2uE13u+oBgpI+d3UbAsif/grrWcCCq31k2KEaBy/xQSj4B0QRkUecOptOyJI3Q4YZFgRKVORCj7W9YsXdKuH6IamLVTAs2lI5l4PjUYM6KGw4bK3pklXX5duYi0nL/wWmBX1HjQhFXb/2WG2Z62k9BWwthf4Dk5bkmKgIgfbguGv5ml4+58nb3d0a4vKEIIw4J8Tzgm9JtM/boHcyKJk/eF0g6y46Xlt7N2GYt3Ruw5P3+m1PXISklfX1FgmFPCkYQ/h73v+Dkuc504lEiqi5bZMNp5vf7morx2FHN+HD9XQMWcZneyEUEcGj95sIqcpPxAvbOULiiiPRsnw1k3OGu3M3U4dS3u7zOkfwftLztfzkF19APoDTfllJ4gds5FfOG/WNyGnI1BlETK7HPy/HVUxBSgelSmcxcNPZf1MoogDSrOJmpkxK/SoTFdRJRbEldREIMJo7L5WJiuQ== jason.hardman@churchofjesuschrist.org' > /home/jason/.ssh/authorized_keys
              chown jason:jason /home/jason/.ssh/authorized_keys
              chmod 600 /home/jason/.ssh/authorized_keys

              # Configure SSH to use port 52020 and disable port 22
              sed -i 's/#Port 22/Port 52020/' /etc/ssh/sshd_config
              sed -i '/Port 22/d' /etc/ssh/sshd_config

              # Remove default Nginx Configuration
              rm /etc/nginx/sites-enabled/default

              # Create a web root directory and add Minesweeper game files
              mkdir -p /var/www/minesweeper

              # Put fils in place
              cp /home/ubuntu/index.html /var/www/minesweeper/
              cp /home/ubuntu/minesweeper.js /var/www/minesweeper/
              cp /home/ubuntu/minesweeper /etc/nginx/sites-available/minesweeper
              
              # Enable the new Nginx configuration
              ln -s /etc/nginx/sites-available/minesweeper /ect/nginx/sites-enabled/minesweeper

              # Restart services
              systemctl restart nginx
              systemctl restart sshd
              EOF
}

