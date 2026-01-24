# n8n with PostgreSQL, Redis Queue Mode, Python and pnpm Support

Este projeto configura o n8n em **Queue Mode** com PostgreSQL como banco de dados, Redis para gerenciamento de filas, suporte completo ao Python e gerenciamento de dependências JavaScript/Node.js via pnpm para automações avançadas e escaláveis.

## ⚡ Recursos Principais

- **Queue Mode**: Execuções distribuídas usando Redis como broker de mensagens
- **Workers Escaláveis**: Suporta múltiplos workers para processar workflows em paralelo
- **PostgreSQL**: Banco de dados robusto para persistir workflows e execuções
- **Redis**: Gerenciamento de filas para alta performance
- **Python 3**: Suporte completo para scripts Python nos workflows
- **pnpm**: Gerenciador de pacotes Node.js moderno e eficiente
- **Dependências Customizadas**: Bibliotecas JavaScript pré-instaladas

## Estrutura do Projeto

- **Dockerfile**: Imagem customizada do n8n com Python 3, pnpm e dependências customizadas
- **docker-compose.yml**: Orquestração dos serviços (n8n main + workers + PostgreSQL + Redis)
- **package.json**: Dependências JavaScript/Node.js para uso nos Code Nodes
- **pnpm-lock.yaml**: Lock file das dependências
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

### 2. Construir e iniciar os serviços

```bash
docker-compose up -d --build
```

### 3. Escalar workers (opcional)

Para melhor performance, escale o número de workers:

```bash
docker-compose up -d --scale n8n-worker=3
```

### 4. Acessar o n8n

Acesse [http://localhost:5678](http://localhost:5678) para configurar sua conta inicial.

### 5. Parar os serviços

```bash
docker-compose stop
```

## Arquitetura Queue Mode

O projeto utiliza o **Queue Mode** do n8n para máxima escalabilidade:

```
┌──────────────┐     ┌──────────┐     ┌────────────────┐
│   Triggers   │────>│  Redis   │────>│   Worker 1     │
│   Webhooks   │     │  (Queue) │     │   Worker 2     │
│   n8n Main   │     │          │     │   Worker 3...  │
└──────────────┘     └──────────┘     └────────────────┘
       │                                       │
       └───────────────────┬───────────────────┘
                           │
                    ┌──────▼──────┐
                    │ PostgreSQL  │
                    └─────────────┘
```

### Como funciona:

1. **n8n Main**: Recebe triggers e webhooks, cria execuções na fila Redis
2. **Redis**: Mantém a fila de execuções pendentes
3. **Workers**: Processam workflows da fila em paralelo
4. **PostgreSQL**: Armazena workflows, credenciais e resultados

## Serviços Disponíveis

- **n8n (main)**: Interface web e gerenciador de triggers - `http://localhost:5678`
- **n8n-worker**: Processadores de workflows (escalável)
- **PostgreSQL**: Banco de dados para persistir workflows e dados - porta `5432`
- **Redis**: Broker de mensagens para queue mode - porta `6379`
- **Python 3**: Suporte completo para scripts Python nos workflows
- **pnpm**: Gerenciador de pacotes Node.js moderno e eficiente
- **Dependências JavaScript**: Bibliotecas pré-instaladas (crypto-js, axios, lodash, date-fns, moment, cheerio)

## Usando Dependências Externas nos Code Nodes

Este projeto está configurado para permitir o uso de módulos externos nos Code Nodes do n8n. As seguintes bibliotecas estão disponíveis:

- **crypto-js**: Criptografia e hashing
- **axios**: Cliente HTTP para APIs
- **lodash**: Utilitários JavaScript
- **date-fns**: Manipulação de datas
- **moment**: Manipulação de datas (legado)

### Exemplo de uso no Code Node:

```javascript
// Usando crypto-js para criar hash
const CryptoJS = require('crypto-js');
const hash = CryptoJS.SHA256("Hello World").toString();

// Usando axios para fazer requisições HTTP
const axios = require('axios');
const response = await axios.get('https://api.example.com/data');

// Usando lodash para manipular arrays/objetos
const _ = require('lodash');
const uniqueItems = _.uniq([1, 2, 2, 3, 3, 4]);

return { hash, data: response.data, uniqueItems };
```

### Adicionando novas dependências:

1. Adicione a dependência no `package.json`
2. Adicione o nome do módulo na variável `NODE_FUNCTION_ALLOW_EXTERNAL` no `docker-compose.yml`
3. Reconstrua o container: `docker-compose build n8n && docker-compose up -d`

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

### Variáveis de Ambiente

As configurações do banco PostgreSQL podem ser alteradas no arquivo `.env`:

- `POSTGRES_USER`: Usuário administrador do PostgreSQL
- `POSTGRES_PASSWORD`: Senha do administrador
- `POSTGRES_DB`: Nome do banco de dados
- `POSTGRES_NON_ROOT_USER`: Usuário para o n8n
- `POSTGRES_NON_ROOT_PASSWORD`: Senha do usuário n8n

### Configurações do Docker Compose

O arquivo `docker-compose.yml` inclui as seguintes configurações importantes:

- `NODE_PATH`: Caminho para as dependências customizadas (`/home/node/custom-deps/node_modules`)
- `NODE_FUNCTION_ALLOW_EXTERNAL`: Lista de módulos externos permitidos nos Code Nodes

### Estrutura de Dependências

As dependências JavaScript são instaladas em `/home/node/custom-deps/node_modules` e são gerenciadas pelo pnpm, proporcionando:

- Instalação mais rápida
- Menor uso de espaço em disco
- Melhor resolução de dependências

- Lock file para builds reproduzíveis

## Deploy para Produção

### Devopness

Para fazer deploy no Devopness, use as seguintes configurações:

**Framework:** Docker (No Framework)

**Root directory:** `/`

**Build command:** 
```bash
docker-compose build
```

**Start command:**
```bash
docker-compose up -d
```

**Portas necessárias:**
- `5678` - Interface web do n8n
- `5432` - PostgreSQL (apenas para conexões internas)
- `6379` - Redis (apenas para conexões internas)

### Variáveis de Ambiente Necessárias

Configure no painel do Devopness:

```env
POSTGRES_USER=admin
POSTGRES_PASSWORD=sua_senha_segura
POSTGRES_DB=n8n_db
POSTGRES_NON_ROOT_USER=n8n_user
POSTGRES_NON_ROOT_PASSWORD=senha_n8n
REDIS_PASSWORD=senha_redis_segura
WEBHOOK_URL=https://seu-dominio.com
N8N_ENCRYPTION_KEY=gere_uma_chave_aleatoria_de_32_caracteres
```

### Escalabilidade

Para aumentar a capacidade de processamento:

```bash
docker-compose up -d --scale n8n-worker=5
```

Recomendações:
- **Desenvolvimento**: 1 worker
- **Produção pequena**: 2-3 workers
- **Produção média**: 3-5 workers
- **Alta demanda**: 5+ workers

### Portas
- **Interface n8n**: `http://localhost:5678`
- **PostgreSQL**: `5432` (interno)
- **Redis**: `6379` (interno)
