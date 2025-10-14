# n8n with PostgreSQL and Python Support

Este projeto configura o n8n com PostgreSQL como banco de dados e suporte completo ao Python para automações avançadas.

## Estrutura do Projeto

- **Dockerfile**: Imagem customizada do n8n com Python 3 e pipx
- **docker-compose.yml**: Orquestração dos serviços (n8n + PostgreSQL)
- **init-data.sh**: Script de inicialização do banco PostgreSQL
- **.env**: Configurações de ambiente (credenciais, etc.)

## Pré-requisitos

- Docker e Docker Compose instalados
- Arquivo `.env` configurado com suas credenciais

## Instalação e Execução

### 1. Configurar variáveis de ambiente

**IMPORTANTE:** Configure o arquivo `.env` antes de iniciar:

```bash
cp .env.example .env
# Edite o .env com suas credenciais
```

### 2. Construir a imagem customizada

```bash
docker build -t n8n-python .
```

### 3. Iniciar os serviços

```bash
docker-compose up -d
```

### 4. Acessar o n8n

Acesse [http://localhost:5678](http://localhost:5678) para configurar sua conta inicial.

### 5. Parar os serviços

```bash
docker-compose stop
```

## Recursos Disponíveis

- **n8n**: Plataforma de automação com interface web
- **PostgreSQL**: Banco de dados para persistir workflows e dados
- **Python 3**: Suporte completo para scripts Python nos workflows
- **pipx**: Gerenciador de pacotes Python isolado

## Gestão de Workflows

### Exportar workflows (CLI - Recomendado)
```powershell
cd scripts
.\export-workflows-cli.ps1
```

### Importar workflows (CLI - Recomendado)
```powershell
cd scripts
.\import-workflows-cli.ps1
```

### Exportar via API REST (alternativa)
```powershell
cd scripts
.\export-workflows.ps1
```

**Para mais detalhes:** Consulte [scripts/README.md](scripts/README.md)

## Configuração

As configurações do banco PostgreSQL podem ser alteradas no arquivo `.env`:

- `POSTGRES_USER`: Usuário administrador do PostgreSQL
- `POSTGRES_PASSWORD`: Senha do administrador
- `POSTGRES_DB`: Nome do banco de dados
- `POSTGRES_NON_ROOT_USER`: Usuário para o n8n
- `POSTGRES_NON_ROOT_PASSWORD`: Senha do usuário n8n