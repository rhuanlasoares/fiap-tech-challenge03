#!bin/bash

ENVIRONMENT=${1:-local}

echo "------------------------------------------"
echo "Ambiente selecionado: ${ENVIRONMENT^^}" # Exibe em maiúsculo
echo "------------------------------------------"

if [ "$ENVIRONMENT" == "prod" ]; then
    echo "Buscando IP no Google Cloud..."
    PROJECT_ID="ces-igniteprogram"
    export GATEWAY_IP=$(gcloud compute addresses describe gke-ip-lb --global --format='value(address)' --project $PROJECT_ID)
    K8S_DIR="k8s"
    gcloud container clusters get-credentials gke-rhuan --region southamerica-east1 --project $PROJECT_ID
elif [ "$ENVIRONMENT" == "local" ]; then
    echo "Buscando IP no Kind (Local)..."
    K8S_DIR="k8s_kind"

    # Loop para verificar a existência do IP
    export GATEWAY_IP=""
    echo "Aguardando o Gateway obter um endereço IP..."

    while [ -z "$GATEWAY_IP" ]; do
        export GATEWAY_IP=$(kubectl get gateway gateway-applications -n gateway-api-ns -o jsonpath='{.status.addresses[0].value}' 2>/dev/null)

        if [ -z "$GATEWAY_IP" ]; then
            echo -n "." # Printa um ponto para mostrar progresso
            sleep 2
        fi
    done
    echo -e "\nIP do Gateway obtido: $GATEWAY_IP"

else
    echo "Ambiente inválido. Use 'prod' ou 'local'."
    exit 1
fi


envsubst < $K8S_DIR/auth-service/auth-http-route.yaml.template > $K8S_DIR/auth-service/auth-http-route.yaml
envsubst < $K8S_DIR/flag-service/flag-http-route.yaml.template > $K8S_DIR/flag-service/flag-http-route.yaml
envsubst < $K8S_DIR/targeting-service/targeting-http-route.yaml.template > $K8S_DIR/targeting-service/targeting-http-route.yaml
envsubst < $K8S_DIR/evaluation-service/evaluation-http-route.yaml.template > $K8S_DIR/evaluation-service/evaluation-http-route.yaml
envsubst < $K8S_DIR/analytics-service/analytics-http-route.yaml.template > $K8S_DIR/analytics-service/analytics-http-route.yaml
envsubst < $K8S_DIR/monitoring/monitoring-http-route.yaml.template > $K8S_DIR/monitoring/monitoring-http-route.yaml
envsubst < $K8S_DIR/argocd/argocd-http-route.yaml.template > $K8S_DIR/argocd/argocd-http-route.yaml

ansible-playbook -i /etc/ansible/hosts iac/ansible/playbooks/namespaces.yaml -e "env=$K8S_DIR"
ansible-playbook -i /etc/ansible/hosts iac/ansible/playbooks/keda.yaml -e "env=$K8S_DIR"

if [ "$ENVIRONMENT" == "prod" ]; then
    ansible-playbook -i /etc/ansible/hosts iac/ansible/playbooks/monitoring.yaml -e "env=$K8S_DIR"
    ansible-playbook -i /etc/ansible/hosts iac/ansible/playbooks/argocd.yaml -e "env=$K8S_DIR"
fi

ansible-playbook -i /etc/ansible/hosts iac/ansible/playbooks/applications.yaml -e "env=$K8S_DIR"
