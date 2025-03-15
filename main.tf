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

  # Allow SSH on port 22 temporarily for provisioning
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting this to your IP for security
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

  tags = {
    Name = "web-server"
  }

  # Connection block for provisioners using SSH on port 22
  connection {
    type        = "ssh"
    user        = "admin" # Default Debian user
    host        = self.public_ip
    port        = 22 # Provisioners use port 22 before user_data changes it
  }

  # Provisioners to upload files
  provisioner "file" {
    source      = "index.html"
    destination = "/home/admin/index.html"
  }

  provisioner "file" {
    source      = "minesweeper.js"
    destination = "/home/admin/minesweeper.js"
  }

  # User data to configure the instance after provisioning
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
              echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGWw2BaLd6HAKnMRQORxYiiKyhv8AH3YyPqKt19iDdUipeWrb25ZGBNnYlfygScOWOx+hKkClxd7xYlbmXX5UXimECuVNhcyMDLSf2H3UBaCbpKljvKA6DTPLRqjNIBj6J/4t2hlnam398hcziDegUQ35bjSSYO6CHDtY3LPxBFyj4cSc1sy7eZORfOScL2X2cUVyMa7z25eJF2kj/51w94N9ZNch1SYIPsHQU8rRqbjQlXhyGTfTHwigBCQCDGzvefbXNMfFSWI4nn1fG4cCPXHqDODXLkGBIsmVdgnVJTL4I6pm61dEN+ch+1pCehINH6buTeWZHOKE1OBDWSPwx5C5z8uWQlYy8ZdRh4XPmFRbNXc+2Br6IQjSA/SqfUy26DVjjgGONuqAO/XsEkmrqWD3SI1NlUjtjLPsBs5gkDdZkoBIA3e5xPBFiqx7dnTx757SaTiT/k2bxkfe0sZFSQV37ix//wBIny2DOQzIdbI7auoLb/VcSjpGhfzBU2uZjCSf94q03BLBCjdxLUqL+g/bFLrMb8xeA6NW9VyfMqF8GicEcx9R+JZSPmRtopDpe7OuPcYstmPCUn17sBoy/S15+6NSZC/Rppd8QoS+fli0jhNIyIezAFfvcu1t3QImRzdSO2+IuLIqlZMLemCYjHuN59tbw5iIV68wzsxuEBQ== jasonhardman@workmint-vm' > /home/jason/.ssh/authorized_keys
              chown jason:jason /home/jason/.ssh/authorized_keys
              chmod 600 /home/jason/.ssh/authorized_keys

              # Configure SSH to use port 52020
              # sed -i 's/#Port 22/Port 52020/' /etc/ssh/sshd_config
              # sed -i '/Port 22/d' /etc/ssh/sshd_config
              sed -i 's/#Port 22/Port 2020/' /etc/ssh/sshd_config

              # Remove default Nginx configuration
              rm -f /etc/nginx/sites-enabled/default

              # Create web root directory and copy files
              mkdir -p /var/www/minesweeper
              mv /home/admin/index.html /var/www/minesweeper/
              mv /home/admin/minesweeper.js /var/www/minesweeper/

              # Write Nginx config without backslashes
              echo "server {" > /etc/nginx/sites-available/minesweeper
              echo "    listen 80;" >> /etc/nginx/sites-available/minesweeper
              echo "    server_name _;" >> /etc/nginx/sites-available/minesweeper
              echo "    root /var/www/minesweeper;" >> /etc/nginx/sites-available/minesweeper
              echo "    index index.html;" >> /etc/nginx/sites-available/minesweeper
              echo "    location / {" >> /etc/nginx/sites-available/minesweeper
              echo "        try_files \$uri \$uri/ /index.html;" >> /etc/nginx/sites-available/minesweeper
              echo "    }" >> /etc/nginx/sites-available/minesweeper
              echo "}" >> /etc/nginx/sites-available/minesweeper

              # Enable Nginx configuration
              ln -sf /etc/nginx/sites-available/minesweeper /etc/nginx/sites-enabled/minesweeper

              # Restart services
              systemctl restart nginx
              systemctl restart sshd
              EOF
}

output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}