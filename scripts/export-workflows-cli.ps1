# Script PowerShell para exportar workflows do n8n via CLI
# Usa comandos nativos do n8n dentro do container Docker

param(
    [string]$ContainerName = "docker-n8n-n8n-1",
    [string]$OutputDir = "../workflows"
)

# Criar diretório de workflows se não existir
$workflowsPath = Join-Path $PSScriptRoot $OutputDir
if (!(Test-Path $workflowsPath)) {
    New-Item -ItemType Directory -Path $workflowsPath -Force | Out-Null
}

Write-Host "🚀 Exportando workflows do n8n via CLI..." -ForegroundColor Green
Write-Host "Container: $ContainerName" -ForegroundColor Cyan
Write-Host "Destino: $workflowsPath" -ForegroundColor Cyan

# Verificar se container está rodando
try {
    $containerStatus = docker ps --filter "name=$ContainerName" --format "{{.Status}}" 2>$null
    if (-not $containerStatus) {
        Write-Host "❌ Container $ContainerName não está rodando" -ForegroundColor Red
        Write-Host "Execute: docker-compose up -d" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✅ Container encontrado: $containerStatus" -ForegroundColor Green
} catch {
    Write-Host "❌ Erro ao verificar container: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Função para executar comandos no container
function Invoke-N8nCommand {
    param($Command)
    
    try {
        $result = docker exec -u node $ContainerName n8n $Command 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Comando falhou: $result"
        }
        return $result
    } catch {
        throw $_
    }
}

try {
    # Listar workflows primeiro para ver o que temos
    Write-Host "📊 Listando workflows disponíveis..." -ForegroundColor Yellow
    $workflowList = Invoke-N8nCommand "list:workflow"
    
    if ($workflowList -match "No workflows found") {
        Write-Host "📭 Nenhum workflow encontrado" -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "Workflows encontrados:" -ForegroundColor Green
    Write-Host $workflowList
    
    # Criar timestamp para o backup
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    
    # Exportar todos os workflows para um arquivo único
    Write-Host "`n📥 Exportando todos os workflows..." -ForegroundColor Yellow
    $allWorkflowsFile = Join-Path $workflowsPath "all-workflows-$timestamp.json"
    
    # Comando para exportar todos os workflows
    Write-Host "🔄 Executando exportação..." -ForegroundColor Yellow
    docker exec -u node $ContainerName n8n export:workflow --all --output=/tmp/all-workflows.json 2>$null | Out-Null
    
    # Ler o arquivo exportado diretamente
    $exportResult = docker exec -u node $ContainerName cat /tmp/all-workflows.json 2>$null
    
    if ($exportResult) {
        # Salvar resultado
        $exportResult | Out-File -FilePath $allWorkflowsFile -Encoding UTF8
        Write-Host "✅ Todos os workflows exportados para: $allWorkflowsFile" -ForegroundColor Green
        
        # Tentar parsear o JSON para extrair workflows individuais
        try {
            $allWorkflows = $exportResult | ConvertFrom-Json
            
            if ($allWorkflows -is [array]) {
                Write-Host "📦 Extraindo workflows individuais..." -ForegroundColor Yellow
                
                $stats = @{
                    total = $allWorkflows.Count
                    exported = 0
                    failed = 0
                }
                
                foreach ($workflow in $allWorkflows) {
                    try {
                        # Criar nome seguro para arquivo
                        $safeName = $workflow.name -replace '[^\w\s-]', '' -replace '\s+', '-' -replace '^-+|-+$', ''
                        if ([string]::IsNullOrEmpty($safeName)) { $safeName = "unnamed-workflow" }
                        
                        $individualFile = Join-Path $workflowsPath "$($workflow.id)-$safeName-$timestamp.json"
                        
                        # Adicionar metadados
                        $workflowWithMeta = [PSCustomObject]@{
                            exportedAt = $timestamp
                            exportMethod = "n8n-cli"
                            originalId = $workflow.id
                            workflow = $workflow
                        }
                        
                        $workflowWithMeta | ConvertTo-Json -Depth 20 | Out-File -FilePath $individualFile -Encoding UTF8
                        
                        Write-Host "  ✅ $($workflow.name) → $([System.IO.Path]::GetFileName($individualFile))" -ForegroundColor Green
                        $stats.exported++
                        
                    } catch {
                        Write-Host "  ❌ Erro ao processar workflow $($workflow.name): $($_.Exception.Message)" -ForegroundColor Red
                        $stats.failed++
                    }
                }
                
                # Criar resumo da exportação
                $summary = @{
                    exportedAt = $timestamp
                    exportMethod = "n8n-cli"
                    containerName = $ContainerName
                    totalWorkflows = $stats.total
                    exportedIndividually = $stats.exported
                    failed = $stats.failed
                    allWorkflowsFile = [System.IO.Path]::GetFileName($allWorkflowsFile)
                    individualFiles = (Get-ChildItem $workflowsPath -Filter "*-$timestamp.json" | Where-Object { $_.Name -ne [System.IO.Path]::GetFileName($allWorkflowsFile) }).Name
                }
                
                $summaryFile = Join-Path $workflowsPath "_export-summary-$timestamp.json"
                $summary | ConvertTo-Json -Depth 10 | Out-File -FilePath $summaryFile -Encoding UTF8
                
                Write-Host "`n🎉 Exportação concluída!" -ForegroundColor Green
                Write-Host "📁 Arquivos criados em: $workflowsPath" -ForegroundColor Cyan
                Write-Host "📄 Resumo: $([System.IO.Path]::GetFileName($summaryFile))" -ForegroundColor Cyan
                
                Write-Host "`n📈 Estatísticas:" -ForegroundColor Yellow
                Write-Host "  • Total de workflows: $($stats.total)"
                Write-Host "  • Exportados individualmente: $($stats.exported)"
                Write-Host "  • Falharam: $($stats.failed)"
                
            } else {
                Write-Host "⚠️  Formato inesperado do export. Arquivo salvo como: $allWorkflowsFile" -ForegroundColor Yellow
            }
            
        } catch {
            Write-Host "⚠️  Não foi possível processar workflows individuais: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "Arquivo principal salvo em: $allWorkflowsFile" -ForegroundColor Cyan
        }
        
    } else {
        Write-Host "❌ Falha na exportação ou nenhum dado retornado" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "❌ Erro durante exportação: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}