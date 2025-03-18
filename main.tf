provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"] # Debian's AWS account ID
  filter {
    name   = "name"
    values = ["debian-*-amd64-*"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "minesweeper-deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9GZeoVJvQLCCH4xDySbU2i5i5vEL/+vwofAWdvGlmmQykBOYkNKiEOHgLXWgCO5FO7b+lAIDvNBsyrIvL3NLclT+3dDZyxfkslvvIlJiCTUgYAMeIlVoOUO8YJi1x4axxbZNRFEu5Lh4J+R+lUxfc/CH+PxCs2lR7rooyU+N6h/qtjer2YCu6fr82c5OuGqmJaalVD2fe4gpk33wxWMNfql2p+I2uE13u+oBgpI+d3UbAsif/grrWcCCq31k2KEaBy/xQSj4B0QRkUecOptOyJI3Q4YZFgRKVORCj7W9YsXdKuH6IamLVTAs2lI5l4PjUYM6KGw4bK3pklXX5duYi0nL/wWmBX1HjQhFXb/2WG2Z62k9BWwthf4Dk5bkmKgIgfbguGv5ml4+58nb3d0a4vKEIIw4J8Tzgm9JtM/boHcyKJk/eF0g6y46Xlt7N2GYt3Ruw5P3+m1PXISklfX1FgmFPCkYQ/h73v+Dkuc504lEiqi5bZMNp5vf7morx2FHN+HD9XQMWcZneyEUEcGj95sIqcpPxAvbOULiiiPRsnw1k3OGu3M3U4dS3u7zOkfwftLztfzkF19APoDTfllJ4gds5FfOG/WNyGnI1BlETK7HPy/HVUxBSgelSmcxcNPZf1MoogDSrOJmpkxK/SoTFdRJRbEldREIMJo7L5WJiuQ== jason.hardman@churchofjesuschrist.org"
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

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Restrict to your IP for security if desired
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.debian.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = {
    Name = "web-server"
  }

  connection {
    type        = "ssh"
    user        = "admin"
    host        = self.public_ip
    port        = 22
  }

  provisioner "file" {
    source      = "index.html"  # Back to uploading the file
    destination = "/home/admin/index.html"
  }

  provisioner "file" {
    source      = "minesweeper.js"
    destination = "/home/admin/minesweeper.js"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx

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
              echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC9GZeoVJvQLCCH4xDySbU2i5i5vEL/+vwofAWdvGlmmQykBOYkNKiEOHgLXWgCO5FO7b+lAIDvNBsyrIvL3NLclT+3dDZyxfkslvvIlJiCTUgYAMeIlVoOUO8YJi1x4axxbZNRFEu5Lh4J+R+lUxfc/CH+PxCs2lR7rooyU+N6h/qtjer2YCu6fr82c5OuGqmJaalVD2fe4gpk33wxWMNfql2p+I2uE13u+oBgpI+d3UbAsif/grrWcCCq31k2KEaBy/xQSj4B0QRkUecOptOyJI3Q4YZFgRKVORCj7W9YsXdKuH6IamLVTAs2lI5l4PjUYM6KGw4bK3pklXX5duYi0nL/wWmBX1HjQhFXb/2WG2Z62k9BWwthf4Dk5bkmKgIgfbguGv5ml4+58nb3d0a4vKEIIw4J8Tzgm9JtM/boHcyKJk/eF0g6y46Xlt7N2GYt3Ruw5P3+m1PXISklfX1FgmFPCkYQ/h73v+Dkuc504lEiqi5bZMNp5vf7morx2FHN+HD9XQMWcZneyEUEcGj95sIqcpPxAvbOULiiiPRsnw1k3OGu3M3U4dS3u7zOkfwftLztfzkF19APoDTfllJ4gds5FfOG/WNyGnI1BlETK7HPy/HVUxBSgelSmcxcNPZf1MoogDSrOJmpkxK/SoTFdRJRbEldREIMJo7L5WJiuQ== jason.hardman@churchofjesuschrist.org' > /home/jason/.ssh/authorized_keys
              chown jason:jason /home/jason/.ssh/authorized_keys
              chmod 600 /home/jason/.ssh/authorized_keys

              # Configure SSH to use port 52020 and restart sshd
              sed -i 's/#Port 22/Port 52020/' /etc/ssh/sshd_config
              sed -i '/Port 22/d' /etc/ssh/sshd_config
              systemctl restart sshd

              # Remove default Nginx config
              rm -f /etc/nginx/sites-enabled/default

              # Create web root directory and set permissions
              mkdir -p /var/www/minesweeper
              sleep 2
              mv /home/admin/index.html /var/www/minesweeper/ 2>/dev/null || echo "index.html not found"
              mv /home/admin/minesweeper.js /var/www/minesweeper/ 2>/dev/null || echo "minesweeper.js not found"
              chown -R www-data:www-data /var/www/minesweeper
              chmod -R 644 /var/www/minesweeper/*

              # Write Nginx config with charset
              echo "server {" > /etc/nginx/sites-available/minesweeper
              echo "    listen 80;" >> /etc/nginx/sites-available/minesweeper
              echo "    server_name _;" >> /etc/nginx/sites-available/minesweeper
              echo "    charset utf-8;" >> /etc/nginx/sites-available/minesweeper
              echo "    root /var/www/minesweeper;" >> /etc/nginx/sites-available/minesweeper
              echo "    index index.html;" >> /etc/nginx/sites-available/minesweeper
              echo "    location / {" >> /etc/nginx/sites-available/minesweeper
              echo "        try_files \$uri \$uri/ /index.html;" >> /etc/nginx/sites-available/minesweeper
              echo "    }" >> /etc/nginx/sites-available/minesweeper
              echo "}" >> /etc/nginx/sites-available/minesweeper

              # Ensure symlink
              ln -sf /etc/nginx/sites-available/minesweeper /etc/nginx/sites-enabled/minesweeper

              # Restart Nginx
              systemctl stop nginx
              systemctl start nginx
              EOF
}

output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}