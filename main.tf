# Define o provedor da AWS e a região a ser usada
provider "aws" {
  region = "us-east-1"
}

# Variável para definir o nome do projeto
variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "VExpenses"
}

# Variável para definir o nome do candidato
variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "SeuNome"
}

# Gera uma chave privada RSA de 2048 bits para ser usada no acesso SSH
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Cria um par de chaves na AWS usando a chave pública gerada anteriormente
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# Cria uma VPC com o bloco CIDR 10.0.0.0/16 e habilita suporte a DNS
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  # Tags para identificar o recurso
  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"
  }
}

# Cria uma sub-rede dentro da VPC com o bloco CIDR 10.0.1.0/24
# Localizada na zona de disponibilidade us-east-1a
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"
  }
}

# Cria um Internet Gateway, permitindo que a VPC se conecte à internet
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"
  }
}

# Cria uma tabela de rotas para permitir tráfego de saída da VPC para a internet
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  # Adiciona uma rota para permitir tráfego de saída para qualquer endereço IP
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"
  }
}

# Associa a tabela de rotas à sub-rede criada anteriormente
resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table_association"
  }
}

# Cria um grupo de segurança que permite acesso SSH a partir de um IP específico
# e permite todo o tráfego de saída
resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"
  description = "Permitir SSH de um IP específico e todo o tráfego de saída"
  vpc_id      = aws_vpc.main_vpc.id

  # Regra de entrada para permitir SSH (porta 22) a partir de um IP específico
  ingress {
    description = "Allow SSH from trusted IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Substitua "123.456.789.123/32" pelo seu endereço IP público
    cidr_blocks = ["189.35.34.235"]
  }

  # Regra de entrada para permitir HTTP (porta 80)
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permite acesso a partir de qualquer lugar
  }

  # Regra de entrada para permitir HTTPS (porta 443)
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permite acesso a partir de qualquer lugar
  }

  # Regra de saída para permitir todo o tráfego de saída
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"
  }
}

# Busca a imagem (AMI) mais recente do Debian 12
data "aws_ami" "debian12" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # O dono da imagem (ID da conta da Amazon)
  owners = ["679593333241"]
}

# Cria uma instância EC2 com a AMI mais recente do Debian 12
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro" # Tipo da instância (gratuito para testes)
  subnet_id       = aws_subnet.main_subnet.id
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.main_sg.name] # Associa o grupo de segurança criado

  # Associa um IP público à instância
  associate_public_ip_address = true

  # Configura o disco raiz da instância com 20 GB
  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  # Script de inicialização (user_data) que instala e inicia o Nginx
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"
  }
}

# Output da chave privada gerada, usada para acessar a instância EC2 via SSH
output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

# Output do endereço IP público da instância EC2
output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}
