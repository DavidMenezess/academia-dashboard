# Use uma imagem base do Nginx (leve e otimizada)
FROM nginx:alpine

# Instalar dependências necessárias
RUN apk add --no-cache \
    curl \
    jq \
    bash

# Copiar arquivos do site
COPY src/ /usr/share/nginx/html/

# Copiar configuração personalizada do Nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Criar diretório para dados
RUN mkdir -p /app/data

# Copiar script de atualização de dados
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Copiar API
COPY api/ /app/api/

# Expor porta 80
EXPOSE 80

# Script de inicialização limpo
COPY docker-entrypoint-clean.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Comando de inicialização
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
