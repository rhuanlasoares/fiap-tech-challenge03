# 🛡️ DevSecOps Workflows — Documentação

Este repositório utiliza uma arquitetura de CI/CD baseada em **GitHub Actions** orientada a módulos. O objetivo é garantir que todas as aplicações passem por um rigoroso processo de qualidade de código e segurança antes de serem publicadas e atualizadas no ambiente via GitOps.

## 🚀 1. Workflows de Deploy (Pipelines Principais)

Os workflows de deploy são os pontos de entrada para cada serviço. Eles orquestram as chamadas para os workflows reutilizáveis de DevSecOps, garantindo que o ciclo de vida da aplicação siga etapas padronizadas e seguras.

Atualmente, os seguintes serviços possuem pipelines de deploy configurados:

* **Python:** `analytics-service`, `flag-service`, `targeting-service`.
* **Golang:** `auth-service`, `evaluation-service`.

### Gatilhos de Execução (Triggers)

Todos os pipelines principais são acionados nas seguintes condições:

* **Push** na branch `main`.
* **Pull Request** para a branch `main`.
* **Disparo manual** (`workflow_dispatch`).

### Ordem de Execução (Pipeline Flow)

Cada pipeline executa as etapas estritamente na seguinte ordem:

1. **Lint** (Qualidade e Formatação)
2. **SCA** (Análise de Composição de Software)
3. **SAST** (Análise Estática de Segurança)
4. **Container Scan** (Varredura na Imagem Docker)
5. **Build, Push & GitOps** (Construção e Atualização de Manifestos)

---

## ♻️ 2. Workflows Reutilizáveis (Módulos DevSecOps)

Os pipelines principais delegam a execução das tarefas para arquivos reutilizáveis (`workflow_call`). Abaixo estão os detalhes de cada módulo.

### 2.1. Lint (`reusable-lint.yaml`)

Responsável por garantir o padrão visual e as boas práticas da linguagem.

* **Comportamento Inteligente:** Tenta corrigir erros de formatação automaticamente e realiza o *commit* das mudanças de volta na branch `main`.
* **Stack Python:** Utiliza `black` e `isort` para formatação automática; valida estilo com `flake8` e `pylint`.
* **Stack Go:** Utiliza `gofmt` e `golangci-lint` (com a flag `--fix`).
* **Relatório:** Gera uma *Issue* no GitHub detalhando as correções automáticas e listando erros residuais que precisam de intervenção manual.

### 2.2. SCA — Software Composition Analysis (`reusable-sca.yaml`)

Analisa as dependências de terceiros (bibliotecas) do projeto em busca de vulnerabilidades conhecidas (CVEs).

* **Ferramentas:**
* **Trivy:** Realiza varredura no sistema de arquivos, bloqueando o pipeline caso encontre falhas **CRITICAL** (se configurado).
* **OWASP Dependency Check:** Segunda camada de segurança configurada para falhar o pipeline caso encontre vulnerabilidades com score **CVSS 9 ou superior**.


* **Relatório:** Abre ou atualiza *Issues* no GitHub separadas para os achados do Trivy e do OWASP.

### 2.3. SAST — Static Application Security Testing (`reusable-sast.yaml`)

Busca falhas de segurança diretamente no código-fonte desenvolvido e vazamento de credenciais.

* **Stack Python:** Utiliza o `bandit`. Falha o pipeline se encontrar vulnerabilidades **HIGH**.
* **Stack Go:** Utiliza o `gosec`. Falha o pipeline se encontrar vulnerabilidades **HIGH** ou **CRITICAL**.
* **Secret Scan:** Utiliza o Trivy (`scan-type: fs`, scanner `secret`) para varrer todo o diretório em busca de senhas, chaves de API e tokens expostos. Bloqueia o deploy se encontrar segredos **HIGH** ou **CRITICAL**.
* **Relatório:** Consolida os achados e documenta na aba de *Issues* do repositório.

### 2.4. Container Scan (`reusable-container-scan.yaml`)

Focado na segurança do empacotamento da aplicação antes do envio para o *registry*.

* **Build Local:** Constrói a imagem Docker localmente no runner sem fazer o push.
* **Varredura de Configuração (Misconfigurations):** Usa o Trivy para analisar o `Dockerfile` atrás de más práticas (ex: rodar imagem como *root*). Falha em falhas **HIGH** ou **CRITICAL**.
* **Varredura de Imagem (CVEs):** O Trivy varre as camadas da imagem recém-construída em busca de pacotes de SO vulneráveis.
* **Relatório:** Cria *Issues* dedicadas para as *Misconfigurations* e para as vulnerabilidades da imagem.

### 2.5. Build, Push e GitOps (`build-push-gitops.yaml`)

A última etapa do pipeline ocorre apenas se todas as validações de segurança e qualidade anteriores passarem com sucesso.

* **Autenticação:** Utiliza *Workload Identity Federation* (`google-github-actions/auth`) para acessar o Google Cloud de forma segura, sem usar chaves estáticas de longo prazo.
* **Build & Push:** Configura o `Docker Buildx` (aproveitando cache) e envia a imagem com a tag correspondente ao SHA do commit e a tag `latest` para o **Google Artifact Registry (GAR)**.
* **Atualização GitOps (Kustomize):**
1. Instala o `kustomize` no *runner*.
2. Navega até o diretório de manifestos (`k8s/${nameService}`) e executa `kustomize edit set image` para substituir a imagem pela nova versão.
3. Faz o *commit* no próprio repositório com as mudanças no `kustomization.yaml`.
4. Valida os manifestos finais executando `kustomize build` localmente para evitar erros de sintaxe.



---

## 📊 3. Gestão de Vulnerabilidades (Issue Tracking)

Um dos grandes diferenciais destes pipelines é a geração ativa de relatórios. Em vez de obrigar o desenvolvedor a ler os logs do GitHub Actions para entender as falhas, as bibliotecas extraem relatórios JSON (Trivy, Gosec, Bandit, OWASP) e os convertem em formato Markdown.

Esses relatórios utilizam a *Action* `JasonEtco/create-an-issue` para abrir, atualizar e centralizar automaticamente as vulnerabilidades e correções na aba de **Issues do GitHub**, garantindo rastreabilidade e facilitando a gestão do backlog de segurança.