# n8n with PostgreSQL, Python and pnpm Support

Este projeto configura o n8n com PostgreSQL como banco de dados, suporte completo ao Python e gerenciamento de dependências JavaScript/Node.js via pnpm para automações avançadas.

## Estrutura do Projeto

- **Dockerfile**: Imagem customizada do n8n com Python 3, pnpm e dependências customizadas
- **docker-compose.yml**: Orquestração dos serviços (n8n + PostgreSQL)
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

### 2. Construir a imagem customizada

```bash
docker-compose build n8n
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
- **pnpm**: Gerenciador de pacotes Node.js moderno e eficiente
- **Dependências JavaScript**: Bibliotecas pré-instaladas (crypto-js, axios, lodash, date-fns, moment)
- **Módulos Externos**: Configuração para usar bibliotecas externas nos Code Nodes

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