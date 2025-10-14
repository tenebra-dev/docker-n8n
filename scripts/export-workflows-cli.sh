#!/bin/bash

# Script Bash para exportar workflows do n8n via CLI
# Usa comandos nativos do n8n dentro do container Docker

# Parâmetros padrão
CONTAINER_NAME="docker-n8n-n8n-1"
OUTPUT_DIR="../workflows"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para mostrar ajuda
show_help() {
    echo "Uso: $0 [opções]"
    echo "Opções:"
    echo "  -c, --container NOME    Nome do container (padrão: $CONTAINER_NAME)"
    echo "  -o, --output DIR        Diretório de saída (padrão: $OUTPUT_DIR)"
    echo "  -h, --help             Mostrar esta ajuda"
    exit 0
}

# Processar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--container)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}❌ Argumento desconhecido: $1${NC}"
            show_help
            ;;
    esac
done

# Determinar caminho absoluto do diretório de scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOWS_PATH="$(cd "$SCRIPT_DIR" && cd "$OUTPUT_DIR" && pwd)"

# Criar diretório de workflows se não existir
mkdir -p "$WORKFLOWS_PATH"

echo -e "${GREEN}🚀 Exportando workflows do n8n via CLI...${NC}"
echo -e "${CYAN}Container: $CONTAINER_NAME${NC}"
echo -e "${CYAN}Destino: $WORKFLOWS_PATH${NC}"

# Verificar se container está rodando
if ! docker ps --filter "name=$CONTAINER_NAME" --format "{{.Status}}" > /dev/null 2>&1; then
    echo -e "${RED}❌ Container $CONTAINER_NAME não está rodando${NC}"
    echo -e "${YELLOW}Execute: docker-compose up -d${NC}"
    exit 1
fi

CONTAINER_STATUS=$(docker ps --filter "name=$CONTAINER_NAME" --format "{{.Status}}")
echo -e "${GREEN}✅ Container encontrado: $CONTAINER_STATUS${NC}"

# Função para executar comandos no container
invoke_n8n_command() {
    local command="$1"
    
    if ! result=$(docker exec -u node "$CONTAINER_NAME" n8n $command 2>&1); then
        echo -e "${RED}❌ Comando falhou: $result${NC}"
        return 1
    fi
    echo "$result"
    return 0
}

# Listar workflows primeiro para ver o que temos
echo -e "${YELLOW}📊 Listando workflows disponíveis...${NC}"

if ! workflow_list=$(invoke_n8n_command "list:workflow"); then
    echo -e "${RED}❌ Erro ao listar workflows${NC}"
    exit 1
fi

if echo "$workflow_list" | grep -q "No workflows found"; then
    echo -e "${YELLOW}📭 Nenhum workflow encontrado${NC}"
    exit 0
fi

echo -e "${GREEN}Workflows encontrados:${NC}"
echo "$workflow_list"

# Criar timestamp para o backup
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

# Exportar todos os workflows para um arquivo único
echo -e "\n${YELLOW}📥 Exportando todos os workflows...${NC}"
all_workflows_file="$WORKFLOWS_PATH/all-workflows-$timestamp.json"

# Comando para exportar todos os workflows
echo -e "${YELLOW}🔄 Executando exportação...${NC}"
if ! docker exec -u node "$CONTAINER_NAME" n8n export:workflow --all --output=/tmp/all-workflows.json > /dev/null 2>&1; then
    echo -e "${RED}❌ Erro na exportação${NC}"
    exit 1
fi

# Ler o arquivo exportado diretamente
if export_result=$(docker exec -u node "$CONTAINER_NAME" cat /tmp/all-workflows.json 2>/dev/null); then
    # Salvar resultado
    echo "$export_result" > "$all_workflows_file"
    echo -e "${GREEN}✅ Todos os workflows exportados para: $all_workflows_file${NC}"
    
    # Tentar parsear o JSON para extrair workflows individuais
    if command -v jq > /dev/null 2>&1; then
        echo -e "${YELLOW}📦 Extraindo workflows individuais...${NC}"
        
        # Contadores para estatísticas
        total_count=0
        exported_count=0
        failed_count=0
        
        # Verificar se é um array
        if jq -e 'type == "array"' "$all_workflows_file" > /dev/null 2>&1; then
            total_count=$(jq 'length' "$all_workflows_file")
            
            # Extrair cada workflow
            for i in $(seq 0 $((total_count - 1))); do
                workflow=$(jq ".[$i]" "$all_workflows_file")
                workflow_id=$(echo "$workflow" | jq -r '.id // "unknown"')
                workflow_name=$(echo "$workflow" | jq -r '.name // "unnamed"')
                
                # Criar nome seguro para arquivo
                safe_name=$(echo "$workflow_name" | sed 's/[^a-zA-Z0-9 -]//g' | sed 's/  */-/g' | sed 's/^-*\|-*$//g')
                if [ -z "$safe_name" ]; then
                    safe_name="unnamed-workflow"
                fi
                
                individual_file="$WORKFLOWS_PATH/${workflow_id}-${safe_name}-${timestamp}.json"
                
                # Adicionar metadados
                workflow_with_meta=$(jq -n \
                    --arg timestamp "$timestamp" \
                    --arg method "n8n-cli" \
                    --arg original_id "$workflow_id" \
                    --argjson workflow "$workflow" \
                    '{
                        exportedAt: $timestamp,
                        exportMethod: $method,
                        originalId: $original_id,
                        workflow: $workflow
                    }')
                
                if echo "$workflow_with_meta" > "$individual_file"; then
                    echo -e "  ${GREEN}✅ $workflow_name → $(basename "$individual_file")${NC}"
                    ((exported_count++))
                else
                    echo -e "  ${RED}❌ Erro ao processar workflow $workflow_name${NC}"
                    ((failed_count++))
                fi
            done
            
            # Criar resumo da exportação
            summary_file="$WORKFLOWS_PATH/_export-summary-$timestamp.json"
            individual_files=$(ls "$WORKFLOWS_PATH"/*-"$timestamp".json 2>/dev/null | grep -v "$(basename "$all_workflows_file")" | xargs -r basename -a | jq -R . | jq -s .)
            
            jq -n \
                --arg timestamp "$timestamp" \
                --arg method "n8n-cli" \
                --arg container "$CONTAINER_NAME" \
                --arg total "$total_count" \
                --arg exported "$exported_count" \
                --arg failed "$failed_count" \
                --arg all_file "$(basename "$all_workflows_file")" \
                --argjson individual_files "$individual_files" \
                '{
                    exportedAt: $timestamp,
                    exportMethod: $method,
                    containerName: $container,
                    totalWorkflows: ($total | tonumber),
                    exportedIndividually: ($exported | tonumber),
                    failed: ($failed | tonumber),
                    allWorkflowsFile: $all_file,
                    individualFiles: $individual_files
                }' > "$summary_file"
            
            echo -e "\n${GREEN}🎉 Exportação concluída!${NC}"
            echo -e "${CYAN}📁 Arquivos criados em: $WORKFLOWS_PATH${NC}"
            echo -e "${CYAN}📄 Resumo: $(basename "$summary_file")${NC}"
            
            echo -e "\n${YELLOW}📈 Estatísticas:${NC}"
            echo "  • Total de workflows: $total_count"
            echo "  • Exportados individualmente: $exported_count"
            echo "  • Falharam: $failed_count"
        else
            echo -e "${YELLOW}⚠️  Formato inesperado do export. Arquivo salvo como: $all_workflows_file${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  jq não está instalado. Workflows individuais não foram extraídos.${NC}"
        echo -e "${CYAN}Instale jq para extrair workflows individuais: sudo apt install jq${NC}"
        echo -e "${CYAN}Arquivo principal salvo em: $all_workflows_file${NC}"
    fi
else
    echo -e "${RED}❌ Falha na exportação ou nenhum dado retornado${NC}"
    exit 1
fi
