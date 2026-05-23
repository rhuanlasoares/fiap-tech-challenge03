#!/bin/sh
set -e

echo "⏳ Aguardando auth-service..."

until [ "$(curl -s "$AUTH_SERVICE_URL/health" | jq -r '.status')" = "ok" ]; do
  echo "Aguardando auth-service..."
  sleep 2
done

echo "✅ Auth-service está UP!"
echo "🔐 Criando API Key..."

RESPONSE=$(curl -s -X POST "$AUTH_SERVICE_URL/admin/keys" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $MASTER_KEY" \
  -d '{"name": "meu-primeiro-servico"}')

echo $RESPONSE

API_KEY=$(echo "$RESPONSE" | jq -r '.key')

echo "SERVICE_API_KEY=$API_KEY" > /shared/.env.generated

echo "✅ API Key salva!"
