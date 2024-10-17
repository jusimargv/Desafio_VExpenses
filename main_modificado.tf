# Provedor AWS configurado para a região us-east-1
provider "aws" {
  region  = "us-east-1"
  version = "~> 4.0"  # Especificando a versão do provedor para evitar problemas de compatibilidade
}

# Variável para armazenar o nome do projeto
variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "VExpenses"
}

# Variável para armazenar o nome do candidato
variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "SeuNome"
}

# Gerando uma chave privada RSA para a instância EC2
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Criando um par de chaves no AWS com a chave pública gerada
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"  # Nome da chave
  public_key = tls_private_key.ec2_key.public_key_openssh  # Chave pública
}

# Criando uma VPC (Virtual Private Cloud)
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"  # Intervalo CIDR para a VPC
  enable_dns_support   = true  # Habilita suporte a DNS
  enable_dns_hostnames = true  # Habilita nomes de host DNS

  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"  # Nome da VPC
  }
}

# Criando uma sub-rede na VPC
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id  # Referência à VPC
  cidr_block        = "10.0.1.0/24"  # Intervalo CIDR para a sub-rede
  availability_zone = "us-east-1a"  # Zona de disponibilidade

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"  # Nome da sub-rede
  }
}

# Criando um gateway de internet
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id  # Referência à VPC

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"  # Nome do gateway
  }
}

# Criando uma tabela de rotas para a VPC
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id  # Referência à VPC

  route {
    cidr_block = "0.0.0.0/0"  # Rota padrão para tráfego de saída
    gateway_id = aws_internet_gateway.main_igw.id  # Referência ao gateway de internet
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"  # Nome da tabela de rotas
  }
}

# Associando a sub-rede à tabela de rotas
resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id  # Referência à sub-rede
  route_table_id = aws_route_table.main_route_table.id  # Referência à tabela de rotas

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table_association"  # Nome da associação
  }
}

# Criando um grupo de segurança
resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"  # Nome do grupo de segurança
  description = "Permitir SSH de IP específico e todo o tráfego de saída"  # Descrição do grupo
  vpc_id      = aws_vpc.main_vpc.id  # Referência à VPC

  # Regras de entrada
  ingress {
    description      = "Allow SSH from specific IP"  # Descrição da regra
    from_port        = 22  # Porta de entrada para SSH
    to_port          = 22  # Porta de saída para SSH
    protocol         = "tcp"  # Protocolo utilizado
    cidr_blocks      = [var.allowed_ssh_ip]  # IP específico a permitir
    ipv6_cidr_blocks = ["::/0"]  # Permitir IPv6
  }

  # Regras de saída
  egress {
    description      = "Allow all outbound traffic"  # Descrição da regra
    from_port        = 0  # Porta de saída
    to_port          = 0  # Porta de saída
    protocol         = "-1"  # Permitir todos os protocolos
    cidr_blocks      = ["0.0.0.0/0"]  # Permitir todo o tráfego
    ipv6_cidr_blocks = ["::/0"]  # Permitir IPv6
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"  # Nome do grupo de segurança
  }
}

# Recuperando a AMI mais recente do Debian 12
data "aws_ami" "debian12" {
  most_recent = true  # Obtendo a AMI mais recente

  filter {
    name   = "name"  # Filtro para o nome da AMI
    values = ["debian-12-amd64-*"]  # Nome da AMI a ser filtrada
  }

  filter {
    name   = "virtualization-type"  # Filtro para o tipo de virtualização
    values = ["hvm"]  # Tipo de virtualização a ser filtrada
  }

  owners = ["679593333241"]  # ID do proprietário da AMI
}

# Criando uma instância EC2
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id  # Referência à AMI do Debian 12
  instance_type   = "t2.micro"  # Tipo de instância EC2
  subnet_id       = aws_subnet.main_subnet.id  # Referência à sub-rede
  key_name        = aws_key_pair.ec2_key_pair.key_name  # Nome da chave para acesso
  security_groups = [aws_security_group.main_sg.name]  # Referência ao grupo de segurança

  associate_public_ip_address = true  # Associar um IP público à instância

  root_block_device {
    volume_size           = 20  # Tamanho do volume EBS
    volume_type           = "gp2"  # Tipo do volume EBS
    delete_on_termination = true  # Deletar o volume ao encerrar a instância
    encrypted             = true  # Criptografar o volume EBS
  }

  # Script de user_data para instalação automática do Nginx
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y  # Atualiza os pacotes
              apt-get upgrade -y  # Atualiza os pacotes existentes
              apt-get install nginx -y  # Instala o Nginx
              systemctl start nginx  # Inicia o Nginx
              systemctl enable nginx  # Habilita o Nginx para iniciar na inicialização
              EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"  # Nome da instância EC2
  }
}

# Saída da chave privada gerada para acesso à instância EC2
output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem  # Valor da chave privada
  sensitive   = true  # Marcando como sensível
}

# Saída do endereço IP público da instância EC2
output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip  # Endereço IP público da instância
}
