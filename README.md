# fiap-tech-challenge02

Este repositório contém a solução desenvolvida para o Tech Challenge 02 da FIAP (Pós‑Graduação em DevOps e Arquitetura Cloud).

O objetivo do exercício foi construir uma arquitetura de microserviços com suporte completo a infraestrutura como código (Terraform/Ansible), manifestos Kubernetes, contêineres Docker e scripts de automação.

## 📁 Estrutura de diretórios e arquivos principais
### **auth-service, flag-service, targeting-service, evaluation-service e analytics-service**
São os diretórios das aplicações, contendo o código fonte, Dockerfile, arquivo SQL para inicialização do banco de dados, etc.

### **k8s/**
Contém os manifestos Kubernetes para o ambiente de produção. Cada serviço possui seu próprio diretório com arquivos como:
- **Deployments**: Configurações de pods e réplicas.
- **Services**: Exposição de serviços internos e externos.
- **Secrets e ConfigMaps**: Armazenamento de dados sensíveis e configurações.
- **HPA (Horizontal Pod Autoscaler)**: Escalabilidade automática baseada em métricas.
- **Keda**: Escalabilidade baseada em eventos.
- **Gateway API e HTTPRoute**: Roteamento das aplicações na URL.
- **Namespaces**: Organização lógica dos recursos.

### **k8s_kind/**
Manifests Kubernetes adaptados para execução local em um cluster Kind (Kubernetes in Docker). Inclui:
- Configurações de banco de dados locais (PVCs e Deployments).
- Recursos simplificados para testes locais.
- Arquivo `kind-cluster.yaml` para criar o cluster Kind.

### **iac/**
Infraestrutura como código para provisionamento em ambientes reais:
- **terraform/**: Scripts para provisionar recursos na GCP, como GKE, Cloud SQL, Redis, e mais.
  - **modules/**: Módulos reutilizáveis para diferentes serviços (VPC, IAM, etc.).
- **ansible/**: Playbooks para deploy de aplicações, namespaces, monitoramento e KEDA.

### **docker-compose.yaml**
Arquivo de orquestração para levantar todo o ambiente localmente com Docker Compose. Inclui:
- Serviços principais (auth-service, flag-service, etc.).
- Bancos de dados PostgreSQL e Redis.
- Gateway Nginx para roteamento de requisições.

### **kind-cluster.yaml**
Configuração para criar um cluster Kind local. Define:
- Porta 8080 mapeada para o host.
- Nós de controle e mapeamentos adicionais comentados para serviços.

### **nginx.conf**
Configuração do Nginx usado como API Gateway. Roteia requisições para os serviços internos:
- `/auth-service/` → auth-service na porta 8001.
- `/flag-service/` → flag-service na porta 8002.
- `/targeting-service/` → targeting-service na porta 8003.
- `/evaluation-service/` → evaluation-service na porta 8004.
- `/analytics-service/` → analytics-service na porta 8005.

### **Outros scripts**
- **`automacao.sh`**: Automação de tarefas comuns.
```bash
bash automacao.sh <environment>
```
Se o parâmetro for prod, vai construir as imagens e subir para o Artifact Registry.

Se for local, vai construir as imagens e subir para o cluster Kind.

Se for docker, vai rodar o comando do docker compose e subir as aplicações.
- **`generate-key.sh`**: Geração de chaves de API para autenticação.
- **`teste_aplicacoes.sh`**: Automação para testar disponibilidade dos serviços e seus paths.
```bash
bash teste_aplicacoes.sh <environment>
```
Se o parâmetro for prod, vai testar com a URL dos serviços no GKE.

Se for local, vai testar com a URL dos serviços no Kind.

Se for docker, vai testar com a URL dos serviços no docker compose.

- **`ansible.sh`**: Automação para executar os comandos Ansible.
```bash
bash ansible.sh <environment>
```
Se o parâmetro for prod, vai executar os comandos Ansible para subir os serviços no GKE.

Se for local, vai executar os comandos Ansible para subir os serviços no Kind.

- **`ab_stress.sh`**: Automação para estressar um serviço em determinado ambiente.
```bash
bash ab_stress.sh <service> <environment>
```
Se o parâmetro environment for prod, vai estressar os serviços que estão no GKE.

Se o parâmetro environment for local, vai estressar os serviços que estão no Kind.

Se o parâmetro service for auth-service, vai estressar o serviço auth-service. Se o parâmetro for flag-service, vai estressar o serviço flag-service, e assim por diante.

---

# 🛠 Documentação de Ajustes nos Microsserviços

Esta seção detalha as modificações realizadas nos serviços para otimização de build, limpeza de código e compatibilidade com o **Load Balancer** (Roteamento baseado em caminhos).

---

## 🔐 Auth-Service (Go)

### 📦 Dependências e Build

* **`go.mod`**: Removida a linha `github.com/jackc/pgx/v4/stdlib v4.18.3`. A biblioteca não era utilizada e causava falhas na construção da imagem Docker.
* **`go.sum`**: Arquivo regenerado automaticamente para garantir a integridade das dependências atuais.

### 🧹 Refatoração (Limpeza de Imports)

Remoção de pacotes declarados mas não utilizados para reduzir o overhead:

* **`handlers.go`**: Removidos `crypto/sha256` e `encoding/hex`.
* **`key.go`**: Removido `fmt`.
* **`main.go`**: Removido `fmt`.

### 🌐 Roteamento

Adicionado o prefixo `/auth-service` aos endpoints para permitir o mapeamento de backends no Load Balancer:

```go
mux.HandleFunc("/auth-service/health", app.healthHandler)
mux.HandleFunc("/auth-service/validate", app.validateKeyHandler)
mux.Handle("/auth-service/admin/keys", app.masterKeyAuthMiddleware(http.HandlerFunc(app.createKeyHandler)))

```

---

## 🚩 Flag-Service (Python)

### 📦 Dependências

* **`requirements.txt`**: Adicionada a biblioteca `Werkzeug`. Embora seja uma dependência do Flask, a declaração explícita evita erros de importação em determinados ambientes de build.

### 🌐 Roteamento

Atualização das rotas no `app.py` para inclusão do prefixo de contexto:

```python
@app.route('/flag-service/health')
@app.route('/flag-service/flags', methods=['POST', 'GET'])
@app.route('/flag-service/flags/<string:name>', methods=['GET', 'PUT', 'DELETE'])

```

---

## 🎯 Targeting-Service (Python)

### 📦 Dependências

* **`requirements.txt`**: Adicionada a biblioteca `Werkzeug`.

### 🌐 Roteamento

Inclusão do prefixo `/targeting-service` nos endpoints do `app.py`:

```python
@app.route('/targeting-service/health')
@app.route('/targeting-service/rules', methods=['POST'])
@app.route('/targeting-service/rules/<string:flag_name>', methods=['GET', 'PUT', 'DELETE'])

```

---

## 📊 Evaluation-Service (Go)

### 📦 Dependências e Versão

* **`go.mod`**:
* Atualizada a versão da linguagem Go.
* Removida a lib `github.com/onsi/ginkgo v1.16.5`.
* Adicionadas as libs `github.com/davecgh/go-spew v1.1.1` e `golang.org/x/sys v0.17.0`.


* **`go.sum`**: Regenerado durante a execução.

### 🧹 Refatoração

* **`evaluator.go`**: Removido import `context` (não utilizado) e adicionado `os` (necessário para a lógica do sistema).
* **`key.go`**: Removido import `fmt`.

### 🌐 Roteamento

Mapeamento dos endpoints com o prefixo do serviço:

```go
mux.HandleFunc("/evaluation-service/health", app.healthHandler)
mux.HandleFunc("/evaluation-service/evaluate", app.evaluationHandler)

```

---

## 📈 Analytics-Service (Python)

### 📦 Dependências

* **`requirements.txt`**: Inclusão da biblioteca `Werkzeug`.

### 🌐 Roteamento e Health Check

* Adicionado o prefixo `/analytics-service` aos endpoints.
* **Melhoria**: A rota `/analytics-service/health` agora permite a criação de regras de monitoramento (Health Check) específicas para este serviço dentro do Load Balancer.
<!--
# Microsserviços
### Auth-service
No arquivo *go.mod* foi removido a linha *github.com/jackc/pgx/v4/stdlib v4.18.3* pois não é utilizado no código e da erro ao tentar construir a imagem.

O arquivo *go.sum* foi gerado na hora de rodar o código.

No arquivo *handlers.go* foi removido os imports *crypto/sha256* e *encoding/hex* pois não eram utilizados.

No arquivo *key.go* foi removido o import *fmt* pois não era utilizado.

No arquivo *main.go* foi removido o import *fmt* pois não era utilizado. Além disso, foi adicionado /auth-service nos endpoints do serviço, permitindo mapear na hora da construção dos backends no Load Balancer.
```go
mux.HandleFunc("/auth-service/health", app.healthHandler)
mux.HandleFunc("/auth-service/validate", app.validateKeyHandler)
mux.Handle("/auth-service/admin/keys", app.masterKeyAuthMiddleware(http.HandlerFunc(app.createKeyHandler)))
```

### Flag-service
No arquivo *requirements.txt* foi adicionado a biblioteca *Werkzeug* pois mesmo não aparecendo no código, ele é necessario pois o Flask é construído sobre ele.

No arquivo *app.py* do serviço Flag-service foi adicionado /flag-service nos endpoints do serviço, permitindo mapear na hora da construção dos backends no Load Balancer.
```python
@app.route('/flag-service/health')
@app.route('/flag-service/flags', methods=['POST'])
@app.route('/flag-service/flags', methods=['GET'])
@app.route('/flag-service/flags/<string:name>', methods=['GET'])
@app.route('/flag-service/flags/<string:name>', methods=['PUT'])
@app.route('/flag-service/flags/<string:name>', methods=['DELETE'])
```

### Targeting-service
No arquivo *requirements.txt* foi adicionado a biblioteca *Werkzeug* pois mesmo não aparecendo no código, ele é necessario pois o Flask é construído sobre ele.

No arquivo *app.py* do serviço Targeting-service foi adicionado /targeting-service nos endpoints do serviço, permitindo mapear na hora da construção dos backends no Load Balancer.
```python
@app.route('/targeting-service/health')
@app.route('/targeting-service/rules', methods=['POST'])
@app.route('/targeting-service/rules/<string:flag_name>', methods=['GET'])
@app.route('/targeting-service/rules/<string:flag_name>', methods=['PUT'])
@app.route('/targeting-service/rules/<string:flag_name>', methods=['DELETE'])
```

### Evaluation-service
No arquivo *evaluator.go* foi removido o import *context* por não ser utilizado e adicionado o import *os* por ser necessário

No arquivo *go.mod* foi modificado a versão da linguagem, além de remover a lib *github.com/onsi/ginkgo v1.16.5* mas adicionado as libs *github.com/davecgh/go-spew v1.1.1* e *golang.org/x/sys v0.17.0*.

O arquivo *go.sum* foi gerado na hora de rodar o código.

No arquivo *key.go* foi removido o import *fmt* pois não era utilizado.

No arquivo *main.go* foi adicionado /evaluation-service nos endpoints do serviço, permitindo mapear na hora da construção dos backends no Load Balancer.
```go
mux.HandleFunc("/evaluation-service/health", app.healthHandler)
mux.HandleFunc("/evaluation-service/evaluate", app.evaluationHandler)
```

### Analytics-service
No arquivo *requirements.txt* foi adicionado a biblioteca *Werkzeug* pois mesmo não aparecendo no código, ele é necessario pois o Flask é construído sobre ele.

No arquivo *app.py* do serviço Analytics-service foi adicionado /analytics-service nos endpoints do serviço, permitindo mapear na hora da construção dos backends no Load Balancer.
```python
@app.route('/analytics-service/health')
```
Dessa forma, foi possível criar regras de Health Check do Load Balancer específica para esse serviço.

No arquivo *requirements.txt* foi adicionado a biblioteca *Werkzeug* pois mesmo não aparecendo no código, o Flask é construído sobre ele. -->

# Como executar
Para todos os casos, é necessário ativar a conta AWS Academy (ou conta AWS pessoal) e é necessário pegar os valores de AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY e AWS_SESSION_TOKEN e modificar no arquivos que necessitam dessas senhas (docker-compsoe.yaml, TFVARS, e os arquivos secrets do serviços targeting-service, evaluation-service e analytics-service).

# Docker Compose
Para levantar o ambiente local é necessário estar no root do diretório:
```bash
cd /fiap-tech-challenge02
```

Feito isso, é possível rodar o comando para subir o docker compose:
```bash
docker-compose up --build
```

Para testar se os serviços estão funcionando:
```bash
bash teste_aplicacoes.sh docker
```

Para testar o funcionamento do serviço analytics, rode os comandos abaixo:
```bash
docker ps (pegar o container ID do analytics-service)
docker log CONTAINER_ID
```

# Kubernetes (Kind)
Para criar o cluster kind, popular o cluster kind com as iamgens dos serviços, instalar metrics-serverr e rodar o cloud-provider-kind (poder usar Gateway API no kind), rodar o comando abaixo:
```bash
bash automacao.sh
```

Para subir os namespaces, serviços, etc de forma automatizada, rodar o comando abaixo:
```bash
bash ansible.sh local
```

Confirmado que os serviços estão funcionando, é possivel rodar o comando abaixo que vai testar o funcionando das requisições nos serviços:
```bash
bash teste_aplicacoes.sh local
```

# Kubernetes (Produção)
Para deploy em um cluster real (ex.: GKE):

### Terraform
Após ativação da conta AWS Academy é necessário pegar os valores de AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY e AWS_SESSION_TOKEN e modificar no arquivo TFVARS.

Feito isso, é possível rodar os comandos abaixo (Não vai subir de primeira pois irá mencionar um erro na configuração do GKE, no próprio Terraform Registry menciona que é um bug do recurso no provedor, apenas rodar o apply novamente já resolve.)
```bash
terraform -chdir=iac/terraform/ init
terraform -chdir=iac/terraform/ plan
terraform -chdir=iac/terraform/ apply -auto-approve
```

Após subir todos os recursos é possível rodar os comandos do Ansible.

Para subir as imagens para o Artifact Registry:
```bash
bash automacao.sh prod
```

No Playbook de aplicações, é feito uma automação para pegar o IP externo estático que é usado para criar o Gateway API e assim modificar no hostnames dos arquivos HTTRoute dos serviços. Rodar os comandos Ansible abaixo:
```bash
bash ansible.sh prod
```
Confirmado que os serviços estão funcionando, é possivel rodar o comando abaixo que vai testar o funcionando das requisições nos serviços:
```bash
bash teste_aplicacoes.sh prod
```

---
