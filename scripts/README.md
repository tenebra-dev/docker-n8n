# Scripts de Gestão de Workflows n8n

Este diretório contém scripts PowerShell para exportar e importar workflows do n8n usando **CLI nativa** do n8n (mais confiável que API REST).

## 🆕 Versões CLI (Recomendadas)

### 📤 `export-workflows-cli.ps1`
Exporta workflows usando comandos nativos do n8n dentro do container Docker.

**Vantagens:**
- ✅ Sem necessidade de autenticação
- ✅ Acesso direto ao banco de dados
- ✅ Mais rápido e confiável
- ✅ Formato nativo do n8n

**Uso básico:**
```powershell
.\export-workflows-cli.ps1
```

**Parâmetros:**
- `-ContainerName`: Nome do container (padrão: n8n-worknow-n8n-1)
- `-OutputDir`: Diretório de destino (padrão: ../workflows)

### 📥 `import-workflows-cli.ps1`
Importa workflows usando comandos nativos do n8n.

**Uso básico:**
```powershell
.\import-workflows-cli.ps1
```

**Parâmetros:**
- `-ContainerName`: Nome do container (padrão: n8n-worknow-n8n-1)
- `-InputDir`: Diretório de origem (padrão: ../workflows)
- `-InputFile`: Arquivo específico para importar
- `-FromIndividualFiles`: Consolida arquivos individuais para importar


## 🔧 Versões API REST (Mantidas para compatibilidade)

### 📤 `export-workflows.ps1`
Exporta workflows via API REST (requer autenticação se configurada).

### 📥 `import-workflows.ps1`  
Importa workflows via API REST (requer autenticação se configurada).

## Como Usar (CLI - Recomendado)

### 1. Exportar workflows existentes
```powershell
cd scripts
.\export-workflows-cli.ps1
```

### 2. Verificar arquivos exportados
```powershell
ls ../workflows/
```

### 3. Commit no Git
```powershell
cd ..
git add workflows/
git commit -m "feat: adicionar workflows exportados"
```

### 4. Importar em outro ambiente
```powershell
# Clonar repositório
git clone <seu-repo>
cd n8n-worknow/scripts

# Importar workflows
.\import-workflows-cli.ps1
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
- Use `-OverwriteExisting` para atualizar workflows existentes
- Verifique logs de erro no console

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