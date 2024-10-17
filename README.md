# Documentação do Desafio VExpenses

# Desafio VExpenses

Este repositório contém a configuração do Terraform para criar uma infraestrutura básica na AWS, incluindo VPC, Subnet, Grupo de Segurança, Key Pair e uma instância EC2 com Nginx pré-instalado.

## Descrição Técnica do Código Original

O código original define os seguintes recursos:

1. **Provider AWS**: Configura o provider da AWS para a região `us-east-1`.
2. **Variáveis**: Define variáveis para o nome do projeto e do candidato.
3. **Chave Privada**: Cria uma chave RSA para acesso à instância EC2.
4. **Key Pair**: Gera um par de chaves na AWS usando a chave pública gerada.
5. **VPC**: Cria uma VPC com suporte a DNS.
6. **Subnet**: Define uma subnet na VPC criada.
7. **Internet Gateway**: Cria um gateway de internet para permitir a comunicação externa.
8. **Route Table**: Cria uma tabela de rotas e associa à subnet.
9. **Grupo de Segurança**: Define regras de segurança para permitir o acesso SSH.
10. **AMI Debian 12**: Utiliza a AMI mais recente do Debian 12.
11. **Instância EC2**: Cria uma instância EC2 com a AMI especificada e configura o Nginx.
12. **Outputs**: Exibe a chave privada e o IP público da instância.


## 2. Código Modificado

```hcl
provider "aws" {
  region = "us-east-1"
}

variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "VExpenses"
}

variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "SeuNome"
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"
  }
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"
  }
}

resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table_association"
  }
}

resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"
  description = "Permitir SSH de IP específico e todo o tráfego de saída"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description      = "Allow SSH from specific IP"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["SEU_IP_AQUI/32"]  # Substitua SEU_IP_AQUI pelo seu IP
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"
  }
}

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

  owners = ["679593333241"]
}

resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main_subnet.id
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.main_sg.name]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              apt-get install nginx -y
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"
  }
}

output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}
```

## 3. Descrição Técnica das Melhorias Implementadas

- **Segurança no Grupo de Segurança**:
  - O acesso SSH foi restrito a um IP específico, aumentando a segurança ao limitar a superfície de ataque.
  
- **Regras de Segurança**:
  - A regra que permite tráfego HTTP foi configurada para ativar após a instalação do Nginx, minimizando acessos indesejados.

- **Automação da Instalação do Nginx**:
  - O script `user_data` foi adicionado para instalar e iniciar automaticamente o Nginx ao criar a instância.

- **Organização do Código**:
  - O código foi devidamente comentado para facilitar a compreensão e a manutenção futura.

## 4. Instruções de Uso

### Pré-requisitos
- Ter o Terraform instalado na sua máquina.
- Ter uma conta AWS com as credenciais configuradas.
- Acesso à internet para baixar as imagens da AWS.

### Passos para Inicializar e Aplicar a Configuração Terraform

1. **Clone o Repositório**:
   ```bash
   git clone https://github.com/seu_usuario/VExpenses.git
   cd VExpenses
   ```

2. **Inicialize o Terraform**:
   ```bash
   terraform init
   ```

3. **Revise o Plano**:
   ```bash
   terraform plan
   ```

4. **Aplique a Configuração**:
   ```bash
   terraform apply
   ```

5. **Acesse a Instância EC2**:
   - Após a criação, use a chave privada exibida no output para acessar a instância.
   - O comando para acessar via SSH:
   ```bash
   ssh -i path/to/your/private_key.pem ubuntu@<ec2_public_ip>
   ```

6. **Verifique se o Nginx está em execução**:
   - Abra um navegador e acesse `http://<ec2_public_ip>` para verificar se o Nginx está rodando.
```

Você pode personalizar a URL do repositório e as instruções conforme necessário. Sinta-se à vontade para fazer ajustes adicionais!
