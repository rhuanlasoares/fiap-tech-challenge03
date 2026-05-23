#!/bin/bash

ENVIRONMENT=${1:-local}

# Cores para facilitar a leitura
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Definição da URL base
if [ "$ENVIRONMENT" == "prod" ]; then
    echo -e "${BLUE}Buscando IP no Google Cloud...${NC}"
    GATEWAY_IP=$(gcloud compute addresses describe gke-ip-lb --global --format='value(address)' --project ces-igniteprogram 2>/dev/null)
    BASE_URL="https://rhuan-fiap.$GATEWAY_IP.nip.io"
elif [ "$ENVIRONMENT" == "local" ]; then
    echo -e "${BLUE}Buscando IP no Kind (Local)...${NC}"
    GATEWAY_IP=$(kubectl get gateway gateway-applications -n gateway-api-ns -o jsonpath='{.status.addresses[0].value}' 2>/dev/null)
    BASE_URL="http://rhuan-fiap.$GATEWAY_IP.nip.io"
elif [ "$ENVIRONMENT" == "docker" ]; then
    BASE_URL="http://localhost:8080"
else
    echo -e "${RED}Ambiente inválido. Use 'prod', 'local' ou 'docker'.${NC}"
    exit 1
fi

# Validação do IP
if [[ "$ENVIRONMENT" != "docker" && -z "$GATEWAY_IP" ]]; then
    echo -e "${RED}Erro: Não foi possível obter o IP do Gateway.${NC}"
    exit 1
fi

echo -e "${GREEN}Testando via: $BASE_URL${NC}\n"

EXPECTED_RESPONSE='{"status":"ok"}'
if [ "$ENVIRONMENT" = "docker" ]; then
    SERVICES=("auth-service" "flag-service" "targeting-service" "evaluation-service" "analytics-service")
else
    SERVICES=("auth-service" "flag-service" "targeting-service" "evaluation-service")
fi

echo "------------------------------------------"
echo "Iniciando Health Check dos Microsserviços"
echo "------------------------------------------"

FAILED=0
for SERVICE in "${SERVICES[@]}"; do
    # CORREÇÃO: Removido o http:// extra, pois o BASE_URL já possui.
    URL="$BASE_URL/$SERVICE/health"

    RESPONSE=$(curl -s --max-time 5 "$URL")

    if [ "$RESPONSE" == "$EXPECTED_RESPONSE" ]; then
        echo -e "✅ [OK] $SERVICE"
    else
        echo -e "❌ [ERRO] $SERVICE"
        echo "   Recebido: ${RESPONSE:-'Sem resposta/Timeout'}"
        FAILED=$((FAILED + 1))
    fi
done

echo "------------------------------------------"
# CORREÇÃO: Não dar 'exit 0' aqui, senão o script para antes de criar a flag.
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Atenção: $FAILED serviço(s) falharam." # Abortando testes funcionais.${NC}"
fi

# 2. Gerando chave no Auth Service
echo -e "\n${BLUE}1. Gerando chave no Auth Service...${NC}"
RESPONSE=$(curl -s -X POST "$BASE_URL/auth-service/admin/keys" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer super-secret-master-key" \
    -d '{"name": "servico-automacao"}')

API_KEY=$(echo $RESPONSE | jq -r '.key' 2>/dev/null)

if [ "$API_KEY" == "null" ] || [ -z "$API_KEY" ]; then
    echo -e "${RED}Erro ao obter API KEY. Resposta: $RESPONSE${NC}"
    exit 1
fi

echo -e "${GREEN}Chave obtida: $API_KEY${NC}\n"

# 3. Criando Flag no Flag Service
echo -e "${BLUE}2. Criando Flag no Flag Service...${NC}"
FLAG_NAME="flag-$(date +%s)"
curl -s -X POST "$BASE_URL/flag-service/flags" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "{\"name\": \"$FLAG_NAME\", \"description\": \"Ativa via script\", \"is_enabled\": true}"
echo -e "\n"

# 4. Listando Flags
echo -e "${BLUE}3. Listando Flags...${NC}"
curl -s "$BASE_URL/flag-service/flags" \
    -H "Authorization: Bearer $API_KEY"
echo -e "\n"

# 5. Criando Regra no Targeting Service
echo -e "${BLUE}4. Criando Regra no Targeting Service...${NC}"
curl -s -X POST "$BASE_URL/targeting-service/rules" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "{\"flag_name\": \"$FLAG_NAME\", \"is_enabled\": true, \"rules\": {\"type\": \"PERCENTAGE\", \"value\": 50}}"
echo -e "\n"

# 6. Executando Evaluation
echo -e "${BLUE}5. Executando Evaluation...${NC}"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME"
echo -e "\n"

echo -e "${BLUE}5. Executando Evaluation para dar result: false...${NC}"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-abc&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-abc&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-abc&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-abc&flag_name=$FLAG_NAME-1"
echo -e "\n"
# 6. Executando Evaluation
echo -e "${BLUE}5. Executando Evaluation...${NC}"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME"
echo -e "\n"

echo -e "${BLUE}5. Executando Evaluation para dar result: false...${NC}"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-abc&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-abc&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-abc&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-abc&flag_name=$FLAG_NAME-1"
echo -e "\n"
# 6. Executando Evaluation
echo -e "${BLUE}5. Executando Evaluation...${NC}"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME"
echo -e "\n"

echo -e "${BLUE}5. Executando Evaluation para dar result: false...${NC}"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-abc&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-abc&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-abc&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-123&flag_name=$FLAG_NAME-1"
curl -s "$BASE_URL/evaluation-service/evaluate?user_id=user-abc&flag_name=$FLAG_NAME-1"
echo -e "\n"

echo -e "${GREEN}Testes finalizados com sucesso!${NC}"
