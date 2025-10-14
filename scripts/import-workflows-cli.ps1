# Script PowerShell para importar workflows para o n8n via CLI
# Usa comandos nativos do n8n dentro do container Docker

param(
    [string]$ContainerName = "n8n-worknow-n8n-1",
    [string]$InputDir = "../workflows",
    [string]$InputFile = "",
    [switch]$FromIndividualFiles = $false
)

# Verificar parâmetros
$workflowsPath = Join-Path $PSScriptRoot $InputDir
if (!(Test-Path $workflowsPath)) {
    Write-Host "❌ Diretório de workflows não encontrado: $workflowsPath" -ForegroundColor Red
    exit 1
}

Write-Host "🚀 Importando workflows para o n8n via CLI..." -ForegroundColor Green
Write-Host "Container: $ContainerName" -ForegroundColor Cyan
Write-Host "Origem: $workflowsPath" -ForegroundColor Cyan

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
    param($Command, $Arguments = @())
    
    try {
        if ($Arguments.Count -gt 0) {
            $cmdArgs = @($Command) + $Arguments
            Write-Host "🔍 Executando: n8n $Command $($Arguments -join ' ')" -ForegroundColor Cyan
            $result = docker exec -u node $ContainerName n8n @cmdArgs 2>&1
        } else {
            Write-Host "🔍 Executando: n8n $Command" -ForegroundColor Cyan
            $result = docker exec -u node $ContainerName n8n $Command 2>&1
        }
        
        Write-Host "📤 Código de saída: $LASTEXITCODE" -ForegroundColor Cyan
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ Erro na execução: $result" -ForegroundColor Red
            throw "Comando falhou com código $LASTEXITCODE : $result"
        }
        return $result
    } catch {
        throw $_
    }
}

try {
    # Listar workflows atuais antes da importação
    Write-Host "📊 Workflows atuais no n8n:" -ForegroundColor Yellow
    try {
        $currentWorkflows = Invoke-N8nCommand "list:workflow"
        Write-Host $currentWorkflows
    } catch {
        Write-Host "Nenhum workflow atual ou erro ao listar" -ForegroundColor Yellow
    }
    
    # Determinar arquivo para importação
    $fileToImport = ""
    
    if ($FromIndividualFiles) {
        Write-Host "`n🔄 Modo: Importação de arquivos individuais" -ForegroundColor Cyan
        Write-Host "⚠️  ATENÇÃO: Este modo requer reconstrução do arquivo consolidado" -ForegroundColor Yellow
        
        # Buscar arquivos individuais (formato: ID-nome-timestamp.json)
        $individualFiles = Get-ChildItem $workflowsPath -Filter "*-*-*.json" | Where-Object { 
            $_.Name -notlike "_export-summary*" -and $_.Name -notlike "all-workflows*"
        }
        
        if ($individualFiles.Count -eq 0) {
            Write-Host "❌ Nenhum arquivo individual encontrado" -ForegroundColor Red
            exit 1
        }
        
        Write-Host "📦 Encontrados $($individualFiles.Count) arquivos individuais" -ForegroundColor Green
        
        # Consolidar workflows individuais
        $consolidatedWorkflows = @()
        foreach ($file in $individualFiles) {
            try {
                $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
                if ($content.workflow) {
                    $consolidatedWorkflows += $content.workflow
                } else {
                    $consolidatedWorkflows += $content
                }
                Write-Host "  ✅ Adicionado: $($file.Name)" -ForegroundColor Green
            } catch {
                Write-Host "  ❌ Erro ao processar: $($file.Name)" -ForegroundColor Red
            }
        }
        
        # Criar arquivo temporário consolidado
        $tempFile = Join-Path $workflowsPath "temp-consolidated-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $consolidatedWorkflows | ConvertTo-Json -Depth 20 | Out-File -FilePath $tempFile -Encoding UTF8
        $fileToImport = $tempFile
        
    } elseif ($InputFile) {
        # Arquivo específico fornecido
        $fileToImport = if ([System.IO.Path]::IsPathRooted($InputFile)) { $InputFile } else { Join-Path $workflowsPath $InputFile }
        
        if (!(Test-Path $fileToImport)) {
            Write-Host "❌ Arquivo não encontrado: $fileToImport" -ForegroundColor Red
            exit 1
        }
        
    } else {
        # Buscar o arquivo all-workflows mais recente
        $allWorkflowFiles = Get-ChildItem $workflowsPath -Filter "all-workflows-*.json" | Sort-Object LastWriteTime -Descending
        
        if ($allWorkflowFiles.Count -eq 0) {
            Write-Host "❌ Nenhum arquivo all-workflows encontrado" -ForegroundColor Red
            Write-Host "Use -InputFile para especificar um arquivo ou -FromIndividualFiles para consolidar" -ForegroundColor Yellow
            exit 1
        }
        
        $fileToImport = $allWorkflowFiles[0].FullName
        Write-Host "📄 Usando arquivo mais recente: $($allWorkflowFiles[0].Name)" -ForegroundColor Cyan
    }
    
    Write-Host "`n📥 Importando workflows de: $([System.IO.Path]::GetFileName($fileToImport))" -ForegroundColor Yellow
    
    # Copiar arquivo para dentro do container
    $containerTempFile = "/tmp/workflows-to-import.json"
    Write-Host "📋 Copiando arquivo para container..." -ForegroundColor Yellow
    docker cp $fileToImport "${ContainerName}:${containerTempFile}"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Erro ao copiar arquivo para container" -ForegroundColor Red
        exit 1
    }
    
    # Verificar se arquivo foi copiado corretamente
    Write-Host "🔍 Verificando arquivo no container..." -ForegroundColor Yellow
    $fileCheck = docker exec -u node $ContainerName ls -la $containerTempFile 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Arquivo encontrado no container: $fileCheck" -ForegroundColor Green
    } else {
        Write-Host "❌ Arquivo não encontrado no container" -ForegroundColor Red
        exit 1
    }
    
    # Executar importação
    Write-Host "🔄 Executando importação..." -ForegroundColor Yellow
    $importResult = Invoke-N8nCommand "import:workflow" @("-i", $containerTempFile)
    
    Write-Host "`n✅ Resultado da importação:" -ForegroundColor Green
    Write-Host $importResult
    
    # Limpar arquivo temporário do container
    docker exec -u node $ContainerName rm -f $containerTempFile 2>$null
    
    # Limpar arquivo temporário local se foi criado
    if ($FromIndividualFiles -and $tempFile -and (Test-Path $tempFile)) {
        Remove-Item $tempFile -Force
        Write-Host "🧹 Arquivo temporário removido" -ForegroundColor Cyan
    }
    
    # Listar workflows após importação
    Write-Host "`n📊 Workflows após importação:" -ForegroundColor Yellow
    try {
        $finalWorkflows = Invoke-N8nCommand "list:workflow"
        Write-Host $finalWorkflows
    } catch {
        Write-Host "Erro ao listar workflows finais" -ForegroundColor Red
    }
    
    Write-Host "`n🎉 Importação concluída!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Erro durante importação: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}