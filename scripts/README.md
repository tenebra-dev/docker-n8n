# Scripts de Gestão de Workflows n8n

Este diretório contém scripts para exportar e importar workflows do n8n usando **CLI nativa** do n8n (mais confiável que API REST).

Disponível para **Windows (PowerShell)** e **Linux/macOS (Bash)**.

## 🆕 Versões CLI (Recomendadas)

### 📤 Exportação de Workflows

#### Windows PowerShell: `export-workflows-cli.ps1`
```powershell
.\export-workflows-cli.ps1
```

#### Linux/macOS Bash: `export-workflows-cli.sh`
```bash
./export-workflows-cli.sh
```

**Vantagens:**
- ✅ Sem necessidade de autenticação
- ✅ Acesso direto ao banco de dados
- ✅ Mais rápido e confiável
- ✅ Formato nativo do n8n

**Parâmetros comuns:**
- `-c/--container`: Nome do container (padrão: docker-n8n-n8n-1)
- `-o/--output`: Diretório de destino (padrão: ../workflows)

### 📥 Importação de Workflows

#### Windows PowerShell: `import-workflows-cli.ps1`
```powershell
.\import-workflows-cli.ps1
```

#### Linux/macOS Bash: `import-workflows-cli.sh`
```bash
./import-workflows-cli.sh
```

**Parâmetros comuns:**
- `-c/--container`: Nome do container (padrão: docker-n8n-n8n-1)
- `-i/--input`: Diretório de origem (padrão: ../workflows)
- `-f/--file`: Arquivo específico para importar
- `--from-individual`: Consolida arquivos individuais para importar


## 🔧 Versões API REST (Mantidas para compatibilidade)

## 🔧 Versões API REST (Mantidas para compatibilidade)

### 📤 `export-workflows.ps1` (Windows)
Exporta workflows via API REST (requer autenticação se configurada).

### 📥 `import-workflows.ps1` (Windows)
Importa workflows via API REST (requer autenticação se configurada).

## Como Usar (CLI - Recomendado)

### 1. Exportar workflows existentes

#### No Windows:
```powershell
cd scripts
.\export-workflows-cli.ps1
```

#### No Linux/macOS:
```bash
cd scripts
./export-workflows-cli.sh
```

### 2. Verificar arquivos exportados
```bash
ls ../workflows/
```

### 3. Commit no Git
```bash
cd ..
git add workflows/
git commit -m "feat: adicionar workflows exportados"
```

### 4. Importar em outro ambiente

#### No Windows:
```powershell
# Clonar repositório
git clone <seu-repo>
cd docker-n8n/scripts

# Importar workflows
.\import-workflows-cli.ps1
```

#### No Linux/macOS:
```bash
# Clonar repositório
git clone <seu-repo>
cd docker-n8n/scripts

# Importar workflows
./import-workflows-cli.sh
```

## Exemplos de Uso Avançado

### Exportar para diretório específico
```bash
# Linux/macOS
./export-workflows-cli.sh --output /caminho/para/backup

# Windows
.\export-workflows-cli.ps1 -OutputDir "C:\backup\workflows"
```

### Importar arquivo específico
```bash
# Linux/macOS
./import-workflows-cli.sh --file ../workflows/all-workflows-2025-10-14_15-23-46.json

# Windows
.\import-workflows-cli.ps1 -InputFile "..\workflows\all-workflows-2025-10-14_15-23-46.json"
```

### Importar de arquivos individuais
```bash
# Linux/macOS
./import-workflows-cli.sh --from-individual

# Windows
.\import-workflows-cli.ps1 -FromIndividualFiles
```

## Pré-requisitos

### Windows
- PowerShell 5.1+ ou PowerShell Core 7+
- Docker Desktop

### Linux/macOS
- Bash 4.0+
- Docker
- `jq` (para processamento de JSON)
  ```bash
  # Ubuntu/Debian
  sudo apt install jq
  
  # CentOS/RHEL/Fedora
  sudo yum install jq  # ou dnf install jq
  
  # macOS (Homebrew)
  brew install jq
  ```

## Estrutura dos Arquivos

### Workflows Individuais
```json
{
  "name": "Nome do Workflow",
  "nodes": [...],
  "connections": {...},
  "settings": {...},
  "staticData": {...},
  "tags": [...],
  "meta": {
    "exportedAt": "2025-10-14 14:30:00",
    "originalId": "123"
  }
}
```

### Resumo da Exportação
O arquivo `_export-summary.json` contém:
```json
{
  "exportedAt": "2025-10-14 14:30:00",
  "n8nUrl": "http://localhost:5678",
  "totalWorkflows": 5,
  "workflows": [
    {
      "id": "123",
      "name": "Meu Workflow",
      "fileName": "123-meu-workflow.json",
      "nodeCount": 3,
      "active": true
    }
  ]
}
```

## Troubleshooting

### Erro 401 (Não Autorizado)
- Certifique-se de que o n8n está configurado corretamente
- Forneça email e senha quando solicitado
- Verifique se a conta tem permissões adequadas

### Erro de Conexão
- Verifique se o n8n está rodando: `docker ps`
- Teste a URL: `curl http://localhost:5678`
- Verifique a configuração de rede do Docker

### Workflows não importados
- Verifique se os arquivos JSON são válidos
- Use `-OverwriteExisting`/`--overwrite` para atualizar workflows existentes
- Verifique logs de erro no console

### Linux: jq não encontrado
```bash
# Ubuntu/Debian
sudo apt install jq

# CentOS/RHEL/Fedora  
sudo yum install jq  # ou dnf install jq

# macOS
brew install jq
```

### Scripts não executáveis (Linux/macOS)
```bash
chmod +x *.sh
```

## Automação

### Script de Backup Automático
```powershell
# backup-daily.ps1
$date = Get-Date -Format "yyyy-MM-dd"
.\export-workflows.ps1 -OutputDir "../backups/$date"
git add "../backups/$date"
git commit -m "backup: workflows $date"
```

### Integração CI/CD
```yaml
# .github/workflows/sync-workflows.yml
name: Sync Workflows
on:
  push:
    paths: ['workflows/**']
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Import workflows
        run: pwsh scripts/import-workflows.ps1 -N8nUrl ${{ secrets.N8N_URL }}
```