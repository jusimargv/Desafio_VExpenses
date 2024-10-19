
  # **Desafio de Infraestrutura como Código (IaC) com Terraform**

Este projeto implementa uma infraestrutura básica na AWS utilizando **Terraform**. A configuração inclui uma VPC, Subnet, Security Group, Key Pair e uma instância EC2 com o servidor **Nginx** automaticamente instalado.

## **Tabela de Conteúdos**
- [Descrição Técnica](#descrição-técnica)
- [Código Original](#código-original)
- [Mudanças Realizadas](#mudanças-realizadas)
- [Instruções de Uso](#instruções-de-uso)
- [Melhorias Implementadas](#melhorias-implementadas)
- [Recursos Criados](#recursos-criados)
- [Comandos Terraform](#comandos-terraform)
- [Informações Importantes](#informações-importantes)

---

## **Descrição Técnica**

### **Código Original**
1. **Provider AWS**: O provedor AWS é configurado para a região `us-east-1`.
  
2. **Variáveis**:
   - `projeto`: Nome do projeto (default: "VExpenses").
   - `candidato`: Nome do candidato (default: "SeuNome").

3. **TLS Private Key**: Gera uma chave privada RSA de 2048 bits para acesso SSH à instância EC2.

4. **Par de Chaves (Key Pair)**: Cria um par de chaves na AWS usando a chave pública gerada.

5. **VPC e Subnet**:
   - Cria uma VPC com o bloco CIDR `10.0.0.0/16`.
   - Cria uma Subnet com o bloco CIDR `10.0.1.0/24` na zona de disponibilidade `us-east-1a`.

6. **Internet Gateway e Tabela de Rotas**: 
   - Cria um Internet Gateway para permitir a comunicação da VPC com a internet.
   - Cria uma tabela de rotas que permite tráfego de saída (`0.0.0.0/0`).

7. **Grupo de Segurança (Security Group)**:
   - Permite acesso SSH na porta 22 de qualquer IP (`0.0.0.0/0`), o que pode ser um risco de segurança.
   - Permite todo o tráfego de saída.

8. **Instância EC2**: 
   - Cria uma instância EC2 `t2.micro` usando a AMI mais recente do Debian 12.
   - Instala e inicia o Nginx automaticamente usando `user_data`.

9. **Outputs**: 
   - Exibe a chave privada e o IP público da instância EC2.

### **Mudanças Realizadas**
1. **Regras de Segurança**:
   - Restringiu o acesso SSH a um IP específico, aumentando a segurança.
   - Adicionadas regras para permitir tráfego HTTP (porta 80) e HTTPS (porta 443) a partir de qualquer IP. 


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

5. **Verifique se o Nginx está funcionando** acessando o IP público no seu navegador:
   ```
   http://<ip-publico-ec2>
   ```

---

## **Melhorias Implementadas**

1. **Segurança**: O acesso SSH foi restrito a um IP específico, aumentando a segurança do ambiente. Novas regras de segurança permitem o acesso HTTP e HTTPS.
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

