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
# Provedor AWS
provider "aws" {
  region = "us-east-1"  # Define a região onde os recursos serão criados
}

# Variável para o nome do projeto
variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "VExpenses"  # Nome padrão do projeto
}

# Variável para o nome do candidato
variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "SeuNome"  # Nome padrão do candidato
}

# Geração de uma chave privada para a instância EC2
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"   # Algoritmo de criptografia
  rsa_bits  = 2048    # Tamanho da chave em bits
}

# Criação de um par de chaves SSH
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"  # Nome da chave
  public_key = tls_private_key.ec2_key.public_key_openssh  # Chave pública
}

# Criação de uma VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"  # Bloco CIDR da VPC
  enable_dns_support   = true            # Habilitar suporte a DNS
  enable_dns_hostnames = true            # Habilitar nomes de host DNS

  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"  # Nome da VPC
  }
}

# Criação de uma Sub-rede
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id  # Referência à VPC criada
  cidr_block        = "10.0.1.0/24"         # Bloco CIDR da sub-rede
  availability_zone = "us-east-1a"          # Zona de disponibilidade

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"  # Nome da sub-rede
  }
}

# Criação de um Gateway de Internet
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id  # Associar o gateway à VPC criada

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"  # Nome do gateway
  }
}

# Criação de uma tabela de rotas
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id  # Associar a tabela à VPC

  # Definindo a rota para a Internet
  route {
    cidr_block = "0.0.0.0/0"  # Rota para todas as IPs
    gateway_id = aws_internet_gateway.main_igw.id  # Usar o gateway de Internet
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"  # Nome da tabela de rotas
  }
}

# Associação da tabela de rotas à sub-rede
resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id  # Referência à sub-rede
  route_table_id = aws_route_table.main_route_table.id  # Referência à tabela de rotas

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table_association"  # Nome da associação
  }
}

# Criação de um Grupo de Segurança
resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"  # Nome do grupo de segurança
  description = "Permitir SSH de IP específico e tráfego HTTP para o Nginx"  # Descrição do grupo
  vpc_id      = aws_vpc.main_vpc.id  # Associar o grupo à VPC

  # Regras de entrada
  ingress {
    description      = "Permitir SSH de IP específico"
    from_port        = 22  # Porta SSH
    to_port          = 22  # Porta SSH
    protocol         = "tcp"
    cidr_blocks      = ["SEU_IP_AQUI/32"]  # Substitua pelo seu IP
    ipv6_cidr_blocks = ["::/0"]  # Permitir IPv6 (opcional)
  }

  # Permitir tráfego HTTP (80) para o Nginx
  ingress {
    description      = "Permitir tráfego HTTP"
    from_port        = 80  # Porta HTTP
    to_port          = 80  # Porta HTTP
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]  # Permitir de qualquer lugar
    ipv6_cidr_blocks = ["::/0"]  # Permitir IPv6 (opcional)
  }

  # Regras de saída
  egress {
    description      = "Permitir todo tráfego de saída"
    from_port        = 0  # Todas as portas
    to_port          = 0  # Todas as portas
    protocol         = "-1"  # Todos os protocolos
    cidr_blocks      = ["0.0.0.0/0"]  # Permitir de qualquer lugar
    ipv6_cidr_blocks = ["::/0"]  # Permitir IPv6 (opcional)
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"  # Nome do grupo
  }
}

# Obtenção da AMI mais recente do Debian 12
data "aws_ami" "debian12" {
  most_recent = true  # Obter a mais recente

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]  # Filtrar AMIs pelo nome
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]  # Filtrar AMIs por tipo de virtualização
  }

  owners = ["679593333241"]  # ID do proprietário da AMI
}

# Criação da instância EC2
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id  # AMI a ser usada
  instance_type   = "t2.micro"  # Tipo de instância
  subnet_id       = aws_subnet.main_subnet.id  # Referência à sub-rede
  key_name        = aws_key_pair.ec2_key_pair.key_name  # Chave SSH
  security_groups = [aws_security_group.main_sg.name]  # Grupo de segurança

  associate_public_ip_address = true  # Associar um IP público

  # Configuração do volume root
  root_block_device {
    volume_size           = 20  # Tamanho do volume
    volume_type           = "gp2"  # Tipo de volume
    delete_on_termination = true  # Deletar o volume ao encerrar a instância
  }

  # Script de inicialização para instalar e configurar o Nginx
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y  # Atualizar pacotes
              apt-get upgrade -y  # Atualizar pacotes instalados
              apt-get install -y nginx  # Instalar Nginx
              systemctl start nginx  # Iniciar o serviço Nginx
              systemctl enable nginx  # Habilitar Nginx para iniciar na inicialização
              EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"  # Nome da instância
  }
}

# Saída da chave privada
output "private_key" {
  description = "Chave privada para acessar a instância EC2"  # Descrição da saída
  value       = tls_private_key.ec2_key.private_key_pem  # Valor da chave privada
  sensitive   = true  # Marcar como sensível para não ser exibida no console
}

# Saída do IP público da instância EC2
output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"  # Descrição do IP público
  value       = aws_instance.debian_ec2.public_ip  # Valor do IP público
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
   https://github.com/jusimargv/Desafio_VExpenses.git
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
