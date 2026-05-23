#!/bin/sh
set -e

echo "⏳ Aguardando API Key gerada..."

while [ ! -f /shared/.env.generated ]; do
  sleep 1
done

echo "✅ Arquivo encontrado. Carregando variáveis..."

# Exporta todas variáveis do arquivo
set -a
. /shared/.env.generated
set +a

echo "🔐 API_KEY carregada!"
echo "🚀 Iniciando evaluation-service..."

exec /app/evaluation-service
