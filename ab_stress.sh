#!/bin/bash

# Configurações de Estresse (Ajuste conforme necessário)
# CONCURRENCY=1  # Número de requisições simultâneas
# REQUESTS=10     # Total de requisições

# SERVICE=${1}
# ENVIRONMENT=${2:-local}

# # Cores
# GREEN='\033[0;32m'
# RED='\033[0;31m'
# BLUE='\033[0;34m'
# NC='\033[0m'

# if [ -z "$SERVICE" ]; then
#     echo -e "${RED}Erro: Informe o serviço (auth-service, flag-service, etc)${NC}"
#     echo "Uso: bash ab_stress.sh <servico> <ambiente>"
#     exit 1
# fi

# # 1. Descoberta do IP/URL
# if [ "$ENVIRONMENT" == "prod" ]; then
#     GATEWAY_IP=$(gcloud compute addresses describe gke-ip-lb --global --format='value(address)' --project ces-igniteprogram)
#     BASE_URL="https://rhuan-fiap.$GATEWAY_IP.nip.io"
# elif [ "$ENVIRONMENT" == "local" ]; then
#     GATEWAY_IP=$(kubectl get gateway gateway-applications -n gateway-api-ns -o jsonpath='{.status.addresses[0].value}')
#     BASE_URL="http://rhuan-fiap.$GATEWAY_IP.nip.io"
# else
#     echo "Ambiente inválido. Use 'local' ou 'prod'."
#     exit 1
# fi

# echo $BASE_URL

# # 2. Definição do Endpoint por Serviço
# case $SERVICE in
#     "auth-service")
#         ENDPOINT="$BASE_URL/auth-service/health"
#         ;;
#     "flag-service")
#         ENDPOINT="$BASE_URL/flag-service/health"
#         ;;
#     "targeting-service")
#         # Endpoint de leitura costuma ser o melhor para estresse
#         ENDPOINT="$BASE_URL/targeting-service/health"
#         ;;
#     "evaluation-service")
#         # Endpoint de leitura costuma ser o melhor para estresse
#         ENDPOINT="$BASE_URL/evaluation-service/health"
#         ;;
#     *)
#         echo -e "${RED}Serviço desconhecido. Usando rota de health padrão...${NC}"
#         ENDPOINT="$BASE_URL/$SERVICE/health"
#         ;;
# esac

# echo -e "${BLUE}Iniciando estresse no serviço: $SERVICE${NC}"
# echo -e "${BLUE}URL: $ENDPOINT${NC}"
# echo -e "${BLUE}Configuração: $REQUESTS requisições ($CONCURRENCY simultâneas)${NC}\n"

# # 3. Execução do Apache Benchmark
# # -n: total de requests | -c: concorrência | -H: Header se necessário
# ab -n $REQUESTS -c $CONCURRENCY -H "Host: rhuan-fiap.$GATEWAY_IP.nip.io" $ENDPOINT

# echo -e "\n${GREEN}Estresse finalizado!${NC}"

# Configurações de Estresse
CONCURRENCY=10  # Simulação de concorrência (via processos em background)
REQUESTS=200    # Total de requisições

SERVICE=${1}
ENVIRONMENT=${2:-local}

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$SERVICE" ]; then
    echo -e "${RED}Erro: Informe o serviço (auth-service, flag-service, etc)${NC}"
    echo "Uso: bash stress_test.sh <servico> <ambiente>"
    exit 1
fi

# 1. Descoberta do IP/URL
if [ "$ENVIRONMENT" == "prod" ]; then
    GATEWAY_IP=$(gcloud compute addresses describe gke-ip-lb --global --format='value(address)' --project ces-igniteprogram)
    BASE_URL="https://rhuan-fiap.$GATEWAY_IP.nip.io"
elif [ "$ENVIRONMENT" == "local" ]; then
    GATEWAY_IP=$(kubectl get gateway gateway-applications -n gateway-api-ns -o jsonpath='{.status.addresses[0].value}')
    BASE_URL="http://rhuan-fiap.$GATEWAY_IP.nip.io"
else
    echo "Ambiente inválido. Use 'local' ou 'prod'."
    exit 1
fi

# 2. Definição do Endpoint
case $SERVICE in
    "auth-service"|"flag-service"|"targeting-service"|"evaluation-service")
        ENDPOINT="$BASE_URL/$SERVICE/health"
        ;;
    *)
        echo -e "${RED}Serviço desconhecido. Usando rota de health padrão...${NC}"
        ENDPOINT="$BASE_URL/$SERVICE/health"
        ;;
esac

echo -e "${BLUE}Iniciando estresse no serviço: $SERVICE${NC}"
echo -e "${BLUE}URL: $ENDPOINT${NC}"
echo -e "${BLUE}Enviando $REQUESTS requisições...${NC}\n"

# 3. Execução com Curl em Loop
for ((i=1; i<=REQUESTS; i++)); do
    # O -w "%{http_code}" mostra apenas o status da resposta (ex: 200)
    # O -s (silent) e -o /dev/null escondem o corpo do JSON
    # O -k (insecure) ajuda se o certificado gerenciado ainda estiver propagando
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -k -H "Host: rhuan-fiap.$GATEWAY_IP.nip.io" "$ENDPOINT")
    
    if [ "$status_code" -eq 200 ]; then
        echo -e "Requisição #$i: ${GREEN}$status_code OK${NC}"
    else
        echo -e "Requisição #$i: ${RED}$status_code ERRO${NC}"
    fi

    # Lógica simples de concorrência: se atingir o limite, não coloca em background
    if (( i % CONCURRENCY == 0 )); then
        sleep 0.1 # Pequena pausa para não travar o socket local
    fi
done

echo -e "\n${GREEN}Estresse finalizado!${NC}"