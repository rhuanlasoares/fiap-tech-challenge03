#!bin/bash

ENVIRONMENT=${1:-local}
echo "------------------------------------------"
echo "Ambiente selecionado: ${ENVIRONMENT^^}" # Exibe em maiúsculo
echo "------------------------------------------"

if [ "$ENVIRONMENT" == "prod" ]; then
  cd auth-service
  docker build -t southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-auth/auth-service .
  docker push southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-auth/auth-service

  cd ../flag-service
  docker build -t southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-flag/flag-service .
  docker push southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-flag/flag-service

  cd ../targeting-service
  docker build -t southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-targeting/targeting-service .
  docker push southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-targeting/targeting-service

  cd ../evaluation-service
  docker build -t southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-evaluation/evaluation-service -f Dockerfile_prd .
  docker push southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-evaluation/evaluation-service

  cd ../analytics-service
  docker build -t southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-analytics/analytics-service .
  docker push southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-analytics/analytics-service

elif [ "$ENVIRONMENT" == "local" ]; then
  kind create cluster --config kind-cluster.yaml

  cd auth-service
  docker build -t auth-service .

  cd ../flag-service
  docker build -t flag-service .

  cd ../targeting-service
  docker build -t targeting-service .

  cd ../evaluation-service
  docker build -t evaluation-service -f Dockerfile_prd .

  cd ../analytics-service
  docker build -t analytics-service .

  kind load docker-image auth-service --name kind
  kind load docker-image flag-service --name kind
  kind load docker-image targeting-service --name kind
  kind load docker-image evaluation-service --name kind
  kind load docker-image analytics-service --name kind

  kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml

  kubectl patch -n kube-system deployment metrics-server --type=json \
    -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

  VERSION="$(basename $(curl -s -L -o /dev/null -w '%{url_effective}' https://github.com/kubernetes-sigs/cloud-provider-kind/releases/latest))"
  docker run -d --name cloud-provider-kind --rm --network host -v /var/run/docker.sock:/var/run/docker.sock registry.k8s.io/cloud-provider-kind/cloud-controller-manager:${VERSION}
  kubectl create ns gateway-api-ns
  kubectl apply -f ../k8s_kind/gateway-api/

  kubectl create -f https://docs.projectcalico.org/manifests/calico.yaml

elif [ "$ENVIRONMENT" == "docker" ]; then
  docker compose up --build
else
  echo "Ambiente inválido. Use 'prod', 'local' ou 'docker'."
  exit 1
fi

# curl -X POST rhuan-fiap.172.19.0.3.nip.io/auth-service/admin/keys -H "Content-Type: application/json" -H "Authorization: Bearer super-secret-master-key" -d '{"name": "meu-primeiro-servico"}'

# curl -X POST rhuan-fiap.172.19.0.3.nip.io/flag-service/flags -H "Content-Type: application/json" -H "Authorization: Bearer tm_key_cb80c32bad54f53ac96875f4db318fa2266d3ab28a6fd7a0c60d548d0aabe003" -d '{"name": "enable-new-dashboard", "description": "Ativa o novo dashboard para usuários", "is_enabled": true}'
# curl rhuan-fiap.172.19.0.3.nip.io/flag-service/flags -H "Authorization: Bearer tm_key_76f31486f9e3fdacfa316d4d3d08a929012d7295353a5f9b1e7b22ef8f7fb185"

# curl -X POST rhuan-fiap.172.19.0.3.nip.io/targeting-service/rules -H "Content-Type: application/json" -H "Authorization: Bearer tm_key_cb80c32bad54f53ac96875f4db318fa2266d3ab28a6fd7a0c60d548d0aabe003" -d '{"flag_name": "enable-new-dashboard", "is_enabled": true, "rules": {"type": "PERCENTAGE", "value": 50}}'
# curl rhuan-fiap.172.19.0.3.nip.io/targeting-service/rules/enable-new-dashboard -H "Authorization: Bearer tm_key_76f31486f9e3fdacfa316d4d3d08a929012d7295353a5f9b1e7b22ef8f7fb185"

# curl "rhuan-fiap.172.19.0.3.nip.io/evaluation-service/evaluate?user_id=user-123&flag_name=enable-new-dashboard"

# cd auth-service
# docker build -t southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-auth/auth-service .
# docker push southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-auth/auth-service

# cd ../flag-service
# docker build -t southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-flag/flag-service .
# docker push southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-flag/flag-service

# cd ../targeting-service
# docker build -t southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-targeting/targeting-service .
# docker push southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-targeting/targeting-service

# cd ../evaluation-service
# docker build -t southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-evaluation/evaluation-service .
# docker push southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-evaluation/evaluation-service

# cd ../analytics-service
# docker build -t southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-analytics/analytics-service .
# docker push southamerica-east1-docker.pkg.dev/ces-igniteprogram/artreg-analytics/analytics-service

# ansible-playbook -i /etc/ansible/hosts playbooks/polrep.yml
