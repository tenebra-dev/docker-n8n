#!/bin/bash

# Script Bash para importar workflows para o n8n via CLI
# Usa comandos nativos do n8n dentro do container Docker

# Parâmetros padrão
CONTAINER_NAME="docker-n8n-n8n-1"
INPUT_DIR="../workflows"
INPUT_FILE=""
FROM_INDIVIDUAL_FILES=false

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
    echo "  -c, --container NOME       Nome do container (padrão: $CONTAINER_NAME)"
    echo "  -i, --input DIR           Diretório de entrada (padrão: $INPUT_DIR)"
    echo "  -f, --file ARQUIVO        Arquivo específico para importar"
    echo "  --from-individual         Importar de arquivos individuais"
    echo "  -h, --help               Mostrar esta ajuda"
    exit 0
}

# Processar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--container)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        -i|--input)
            INPUT_DIR="$2"
            shift 2
            ;;
        -f|--file)
            INPUT_FILE="$2"
            shift 2
            ;;
        --from-individual)
            FROM_INDIVIDUAL_FILES=true
            shift
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
WORKFLOWS_PATH="$(cd "$SCRIPT_DIR" && cd "$INPUT_DIR" && pwd)"

# Verificar se diretório existe
if [ ! -d "$WORKFLOWS_PATH" ]; then
    echo -e "${RED}❌ Diretório de workflows não encontrado: $WORKFLOWS_PATH${NC}"
    exit 1
fi

echo -e "${GREEN}🚀 Importando workflows para o n8n via CLI...${NC}"
echo -e "${CYAN}Container: $CONTAINER_NAME${NC}"
echo -e "${CYAN}Origem: $WORKFLOWS_PATH${NC}"

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
    shift
    local args=("$@")
    
    echo -e "${CYAN}🔍 Executando: n8n $command ${args[*]}${NC}"
    
    if [ ${#args[@]} -gt 0 ]; then
        result=$(docker exec -u node "$CONTAINER_NAME" n8n "$command" "${args[@]}" 2>&1)
        exit_code=$?
    else
        result=$(docker exec -u node "$CONTAINER_NAME" n8n "$command" 2>&1)
        exit_code=$?
    fi
    
    echo -e "${CYAN}📤 Código de saída: $exit_code${NC}"
    
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}❌ Erro na execução: $result${NC}"
        return 1
    fi
    
    echo "$result"
    return 0
}

# Listar workflows atuais antes da importação
echo -e "${YELLOW}📊 Workflows atuais no n8n:${NC}"
if current_workflows=$(invoke_n8n_command "list:workflow"); then
    echo "$current_workflows"
else
    echo -e "${YELLOW}Nenhum workflow atual ou erro ao listar${NC}"
fi

# Determinar arquivo para importação
file_to_import=""

if [ "$FROM_INDIVIDUAL_FILES" = true ]; then
    echo -e "\n${CYAN}🔄 Modo: Importação de arquivos individuais${NC}"
    echo -e "${YELLOW}⚠️  ATENÇÃO: Este modo requer reconstrução do arquivo consolidado${NC}"
    
    # Buscar arquivos individuais (formato: ID-nome-timestamp.json)
    mapfile -t individual_files < <(find "$WORKFLOWS_PATH" -name "*-*-*.json" -type f | grep -v "_export-summary" | grep -v "all-workflows")
    
    if [ ${#individual_files[@]} -eq 0 ]; then
        echo -e "${RED}❌ Nenhum arquivo individual encontrado${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}📦 Encontrados ${#individual_files[@]} arquivos individuais${NC}"
    
    # Verificar se jq está disponível
    if ! command -v jq > /dev/null 2>&1; then
        echo -e "${RED}❌ jq é necessário para consolidar arquivos individuais${NC}"
        echo -e "${YELLOW}Instale jq: sudo apt install jq${NC}"
        exit 1
    fi
    
    # Consolidar workflows individuais
    temp_file="$WORKFLOWS_PATH/temp-consolidated-$(date +%Y%m%d-%H%M%S).json"
    echo "[]" > "$temp_file"
    
    for file in "${individual_files[@]}"; do
        if content=$(jq -r '.workflow // .' "$file" 2>/dev/null); then
            # Adicionar workflow ao array consolidado
            jq --argjson workflow "$content" '. += [$workflow]' "$temp_file" > "${temp_file}.tmp" && mv "${temp_file}.tmp" "$temp_file"
            echo -e "  ${GREEN}✅ Adicionado: $(basename "$file")${NC}"
        else
            echo -e "  ${RED}❌ Erro ao processar: $(basename "$file")${NC}"
        fi
    done
    
    file_to_import="$temp_file"
    
elif [ -n "$INPUT_FILE" ]; then
    # Arquivo específico fornecido
    if [[ "$INPUT_FILE" = /* ]]; then
        file_to_import="$INPUT_FILE"
    else
        file_to_import="$WORKFLOWS_PATH/$INPUT_FILE"
    fi
    
    if [ ! -f "$file_to_import" ]; then
        echo -e "${RED}❌ Arquivo não encontrado: $file_to_import${NC}"
        exit 1
    fi
    
else
    # Buscar o arquivo all-workflows mais recente
    latest_file=$(find "$WORKFLOWS_PATH" -name "all-workflows-*.json" -type f -printf "%T@ %p\n" | sort -nr | head -1 | cut -d' ' -f2-)
    
    if [ -z "$latest_file" ]; then
        echo -e "${RED}❌ Nenhum arquivo all-workflows encontrado${NC}"
        echo -e "${YELLOW}Use -f para especificar um arquivo ou --from-individual para consolidar${NC}"
        exit 1
    fi
    
    file_to_import="$latest_file"
    echo -e "${CYAN}📄 Usando arquivo mais recente: $(basename "$file_to_import")${NC}"
fi

echo -e "\n${YELLOW}📥 Importando workflows de: $(basename "$file_to_import")${NC}"

# Copiar arquivo para dentro do container
container_temp_file="/tmp/workflows-to-import.json"
echo -e "${YELLOW}📋 Copiando arquivo para container...${NC}"

if ! docker cp "$file_to_import" "${CONTAINER_NAME}:${container_temp_file}"; then
    echo -e "${RED}❌ Erro ao copiar arquivo para container${NC}"
    exit 1
fi

# Verificar se arquivo foi copiado corretamente
echo -e "${YELLOW}🔍 Verificando arquivo no container...${NC}"
if file_check=$(docker exec -u node "$CONTAINER_NAME" ls -la "$container_temp_file" 2>/dev/null); then
    echo -e "${GREEN}✅ Arquivo encontrado no container: $file_check${NC}"
else
    echo -e "${RED}❌ Arquivo não encontrado no container${NC}"
    exit 1
fi

# Executar importação
echo -e "${YELLOW}🔄 Executando importação...${NC}"
if import_result=$(invoke_n8n_command "import:workflow" "-i" "$container_temp_file"); then
    echo -e "\n${GREEN}✅ Resultado da importação:${NC}"
    echo "$import_result"
else
    echo -e "${RED}❌ Erro durante a importação${NC}"
    exit 1
fi

# Limpar arquivo temporário do container
docker exec -u node "$CONTAINER_NAME" rm -f "$container_temp_file" 2>/dev/null

# Limpar arquivo temporário local se foi criado
if [ "$FROM_INDIVIDUAL_FILES" = true ] && [ -n "$temp_file" ] && [ -f "$temp_file" ]; then
    rm -f "$temp_file"
    echo -e "${CYAN}🧹 Arquivo temporário removido${NC}"
fi

# Listar workflows após importação
echo -e "\n${YELLOW}📊 Workflows após importação:${NC}"
if final_workflows=$(invoke_n8n_command "list:workflow"); then
    echo "$final_workflows"
else
    echo -e "${RED}Erro ao listar workflows finais${NC}"
fi

echo -e "\n${GREEN}🎉 Importação concluída!${NC}"
