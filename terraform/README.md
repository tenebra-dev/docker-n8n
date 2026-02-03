# Terraform - Infraestrutura como Código para n8n no GCP

Este diretório contém a configuração Terraform para provisionar automaticamente a infraestrutura n8n no Google Cloud Platform.

## 📋 O que o Terraform vai criar

- ✅ VM no GCP (e2-micro no free tier por padrão)
- ✅ IP externo para acessar
- ✅ Regras de firewall (SSH, HTTP, HTTPS, n8n)
- ✅ Docker e Docker Compose instalados automaticamente
- ✅ Disco de 30GB
- ✅ Tags e labels para organização

## 🚀 Como usar (Passo a passo)

### 1. Instalar Terraform

**Windows:**
```powershell
# Usando Chocolatey
choco install terraform

# Ou baixe manualmente de: https://www.terraform.io/downloads
```

**Verificar instalação:**
```powershell
terraform version
```

### 2. Configurar autenticação GCP

```powershell
# Fazer login no GCP
gcloud auth application-default login

# Definir projeto padrão
gcloud config set project primal-catfish-474613-t4
```

### 3. Inicializar Terraform

```powershell
# Navegar para o diretório terraform
cd terraform

# Inicializar (baixa plugins necessários)
terraform init
```

### 4. Revisar as configurações

Edite o arquivo `terraform.tfvars` se quiser mudar:
- Tipo de máquina (e2-micro, e2-small, e2-medium)
- Região/zona
- Nome da VM
- Tamanho do disco

### 5. Planejar (ver o que será criado)

```powershell
terraform plan
```

Este comando mostra TUDO que vai ser criado **SEM CRIAR NADA**. Revise com calma!

### 6. Aplicar (criar a infraestrutura)

```powershell
terraform apply
```

- Digite `yes` quando perguntar
- Aguarde ~2-3 minutos
- No final, mostra IP da VM e comandos úteis

### 7. Ver outputs (informações úteis)

```powershell
# Ver todos os outputs
terraform output

# Ver só o IP
terraform output vm_external_ip

# Ver URL do n8n
terraform output n8n_url

# Ver comandos para próximos passos
terraform output quickstart_commands
```

## 📦 Próximos passos após criar a VM

### 1. Conectar via SSH
```powershell
# Copie o comando do output
gcloud compute ssh n8n-test-vm --zone=us-central1-a
```

### 2. Aguardar instalação do Docker
```bash
# Na VM, ver progresso da instalação
sudo journalctl -u google-startup-scripts.service -f

# Quando aparecer "Instalação concluída", pressione Ctrl+C
```

### 3. Copiar arquivos do projeto para a VM
```powershell
# No seu PowerShell local (não na VM)
cd ..  # Voltar para o diretório raiz do projeto

gcloud compute scp --recurse `
  docker-compose.yml .env Dockerfile entrypoint.sh init-data.sh `
  package.json pnpm-lock.yaml scripts sql workflows `
  n8n-test-vm:~/docker-n8n --zone=us-central1-a
```

### 4. Subir o n8n
```bash
# Na VM via SSH
cd ~/docker-n8n
docker compose up -d

# Ver logs
docker compose logs -f

# Verificar status
docker compose ps
```

### 5. Acessar no navegador
```
http://SEU_IP_EXTERNO:5678
```

## 💰 Gerenciar custos

### Parar a VM (não paga compute, só storage)
```powershell
gcloud compute instances stop n8n-test-vm --zone=us-central1-a

# Ou via Terraform
terraform apply -var="instance_name=n8n-test-vm" -target=google_compute_instance.n8n_vm
```

### Iniciar a VM novamente
```powershell
gcloud compute instances start n8n-test-vm --zone=us-central1-a
```

### Destruir TUDO (quando não precisar mais)
```powershell
terraform destroy
```
- Digite `yes`
- Tudo será deletado (VM, firewall rules, etc.)
- **CUIDADO**: Dados serão perdidos!

## 📊 Custos estimados

| Machine Type | Região | Custo/mês | No orçamento? |
|-------------|---------|-----------|---------------|
| **e2-micro** | us-central1 | **FREE** | ✅ |
| e2-small | us-central1 | ~$12 (~R$60) | ❌ |
| e2-medium | us-central1 | ~$24 (~R$120) | ❌ |
| e2-medium | southamerica-east1 | ~$30 (~R$150) | ❌ |

**Dica**: Use e2-micro (free tier) ou pare a VM quando não estiver usando!

## 🔧 Comandos úteis

```powershell
# Ver estado atual da infraestrutura
terraform show

# Listar recursos gerenciados
terraform state list

# Ver valor específico
terraform output vm_external_ip

# Formatar código
terraform fmt

# Validar configuração
terraform validate

# Atualizar estado (se mudou algo manualmente)
terraform refresh

# Ver plano sem aplicar
terraform plan -out=tfplan

# Aplicar plano salvo
terraform apply tfplan
```

## 📁 Estrutura dos arquivos

```
terraform/
├── main.tf           # Configuração principal (VM, firewall, etc.)
├── variables.tf      # Definição de variáveis
├── outputs.tf        # Outputs (IP, comandos, etc.)
├── terraform.tfvars  # Seus valores (NÃO COMMITAR se sensível!)
└── README.md         # Este arquivo
```

## 🎓 Aprendendo Terraform

### Conceitos importantes:

1. **Providers**: Conexão com cloud (GCP, AWS, Azure)
2. **Resources**: Coisas criadas (VM, firewall, etc.)
3. **Variables**: Valores configuráveis
4. **Outputs**: Informações úteis depois de criar
5. **State**: Terraform guarda estado em `terraform.tfstate`

### Boas práticas:

- ✅ Sempre rode `terraform plan` antes de `apply`
- ✅ Use `.gitignore` para `terraform.tfstate` e `terraform.tfvars`
- ✅ Comente código para documentar decisões
- ✅ Use variáveis para tornar reutilizável
- ✅ Use `terraform fmt` para formatar código

### Para o currículo:

✨ **Skills que você aprendeu:**
- Infrastructure as Code (IaC)
- Terraform (HCL)
- Google Cloud Platform (GCP)
- Compute Engine
- Firewall management
- Automation scripting
- DevOps practices

## 🆘 Troubleshooting

### Erro: "Provider authentication"
```powershell
gcloud auth application-default login
```

### Erro: "Resource already exists"
```powershell
# Importar recurso existente
terraform import google_compute_instance.n8n_vm projects/PROJECT_ID/zones/ZONE/instances/INSTANCE_NAME
```

### Erro: "Quota exceeded"
- Verifique limites no GCP Console
- Você pode ter atingido o limite de recursos free tier

### VM criada mas Docker não instalou
```bash
# Conectar na VM e verificar logs
sudo journalctl -u google-startup-scripts.service

# Re-executar manualmente
sudo /usr/bin/google_osconfig_agent
```

### Destruir mesmo com erro
```powershell
terraform destroy -auto-approve
```

## 🔐 Segurança

### Restringir acesso só ao seu IP:
Edite `terraform.tfvars`:
```hcl
allowed_ip_ranges = ["SEU_IP_PUBLICO/32"]
```

Descubra seu IP:
```powershell
(Invoke-WebRequest -Uri "https://api.ipify.org").Content
```

### Usar IP estático (opcional):
Descomente no `main.tf`:
```hcl
resource "google_compute_address" "n8n_static_ip" {
  name   = "n8n-static-ip-${var.environment}"
  region = var.region
}
```

## 📚 Recursos para aprender mais

- [Terraform Docs](https://www.terraform.io/docs)
- [GCP Provider Docs](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [GCP Free Tier](https://cloud.google.com/free)

## 🤝 Contribuindo para o Devopness

Agora que você tem a infraestrutura rodando:

1. ✅ VM configurada e acessível
2. ✅ Docker instalado
3. ✅ Pronto para deploy via Devopness

No Devopness, configure:
- Nome: `n8n-test-vm`
- Zona: `us-central1-a`
- IP: (copie do `terraform output vm_external_ip`)

---

**Criado com ❤️ para aprender Terraform e contribuir com open source!**
