# **Desafio de Infraestrutura como Código (IaC) com Terraform**

Este projeto implementa uma infraestrutura básica na AWS utilizando **Terraform**. A configuração inclui uma VPC, Subnet, Security Group, Key Pair e uma instância EC2 com o servidor **Nginx** automaticamente instalado.

## **Tabela de Conteúdos**
- [Descrição Técnica](#descrição-técnica)
- [Instruções de Uso](#instruções-de-uso)
- [Melhorias Implementadas](#melhorias-implementadas)
- [Recursos Criados](#recursos-criados)
- [Comandos Terraform](#comandos-terraform)
- [Informações Importantes](#informações-importantes)

---

## **Descrição Técnica**

### **1. Provider AWS**
O provedor AWS é configurado para a região `us-east-1`.

### **2. Variáveis**
As variáveis permitem personalizar o nome do projeto e do candidato:
- `projeto`: Define o nome do projeto. Valor padrão: `"VExpenses"`.
- `candidato`: Define o nome do candidato. Valor padrão: `"SeuNome"`.

### **3. TLS Private Key**
Uma chave privada RSA de 2048 bits é gerada localmente para acesso SSH à instância EC2.

### **4. Par de Chaves (Key Pair)**
O par de chaves criado é registrado na AWS e vinculado à chave pública gerada.

### **5. VPC e Subnet**
- **VPC**: Uma Virtual Private Cloud (VPC) é criada com o bloco CIDR `10.0.0.0/16`.
- **Subnet**: Uma Subnet é criada com o bloco CIDR `10.0.1.0/24` na zona de disponibilidade `us-east-1a`.

### **6. Internet Gateway e Tabela de Rotas**
- **Internet Gateway**: Conecta a VPC à internet.
- **Route Table**: Cria uma rota padrão (`0.0.0.0/0`) para permitir o tráfego de saída através do Internet Gateway.

### **7. Grupo de Segurança (Security Group)**
- Permite **SSH** na porta 22 a partir de um IP específico (substitua pelo seu IP no código).
- Permite todo o tráfego de saída.

### **8. Instância EC2**
- **AMI**: A imagem mais recente do **Debian 12** é utilizada.
- **Instância**: Um EC2 `t2.micro` (grátis para o nível AWS Free Tier) é criado, associado à Subnet, ao Security Group e à Key Pair gerada.
- **Automação (user_data)**: Um script de inicialização instala e configura automaticamente o servidor **Nginx** na instância.

### **9. Outputs**
- **Chave Privada**: A chave privada gerada é exibida como um output sensível para acesso SSH.
- **IP Público**: O endereço IP público da instância EC2 é exibido para acesso ao servidor.

---

## **Instruções de Uso**

### **Pré-requisitos**
- **Terraform** instalado (versão 0.12 ou superior).
- Uma conta AWS com permissões suficientes para criar recursos como VPC, EC2, etc.
- Substituir o IP na regra do Security Group pelo seu endereço IP público.

### **Passos para Execução**

1. Clone o repositório e entre no diretório:
   ```bash
   git clone https://github.com/jusimargv/Desafio_VExpenses.git
   cd Desafio_VExpenses
   ```

2. Inicialize o Terraform:
   ```bash
   terraform init
   ```

3. Aplique a configuração para criar a infraestrutura:
   ```bash
   terraform apply
   ```

4. O Terraform exibirá a chave privada e o IP público da instância EC2. Use essas informações para acessar a instância via SSH:
   ```bash
   ssh -i <caminho-da-chave-privada> ec2-user@<ip-publico-ec2> 
   ```

<<<<<<< HEAD
---

## **Melhorias Implementadas**

1. **Segurança**: O acesso SSH foi restrito a um IP específico, aumentando a segurança do ambiente.
2. **Automação**: A instalação do servidor **Nginx** é automatizada usando o script `user_data`, que também garante que o serviço inicie automaticamente.

---

## **Recursos Criados**

- VPC com CIDR `10.0.0.0/16`.
- Subnet associada à VPC com CIDR `10.0.1.0/24`.
- Internet Gateway e Tabela de Rotas para permitir tráfego de internet.
- Grupo de Segurança com regras de entrada/saída configuradas.
- Instância EC2 com Debian 12 e Nginx instalado.

---

## **Comandos Terraform**

- **terraform init**: Inicializa o diretório e baixa os provedores necessários.
- **terraform apply**: Cria a infraestrutura descrita no código.
- **terraform destroy**: Destrói a infraestrutura criada.

---

## **Informações Importantes**

- **IP Público**: Certifique-se de adicionar o seu IP público ao grupo de segurança no código antes de executar o Terraform.
- **Custo**: Este código utiliza recursos dentro do nível gratuito da AWS (Free Tier), mas esteja atento ao uso para evitar cobranças.

---

Se houver qualquer dúvida ou problemas durante a configuração, entre em contato.

---

=======
6. **Verifique se o Nginx está em execução**:
    ```
    
   - Abra um navegador e acesse `http://<ec2_public_ip>` para verificar se o Nginx está rodando.



>>>>>>> 9be5bfb37e0b31016014475d28c7bc8877f388e8
