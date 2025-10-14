FROM docker.n8n.io/n8nio/n8n

USER root

# Instalar dependências do sistema incluindo npm
RUN apk add --update python3 py3-pip curl npm

# Instalar pnpm globalmente usando npm
RUN npm install -g pnpm@8.15.0

USER node

# Criar diretório para as dependências customizadas
WORKDIR /home/node/custom-deps

# Copiar package.json e pnpm-lock.yaml para instalar dependências
COPY --chown=node:node package.json pnpm-lock.yaml ./

# Instalar dependências com pnpm
RUN pnpm install --frozen-lockfile

# Configurar NODE_PATH para as dependências customizadas
ENV NODE_PATH="/home/node/custom-deps/node_modules"

# Voltar para o diretório padrão do n8n
WORKDIR /home/node

# Verificar instalações e exibir informações
RUN echo "=== Dependências instaladas ===" && \
    pnpm --version && \
    echo "Node.js: $(node --version)" && \
    echo "Python: $(python3 --version)" && \
    echo "NODE_PATH: $NODE_PATH" && \
    ls -la /home/node/custom-deps/node_modules