# ToggleMaster — Tech Challenge Fase 2 (FIAP Pós Tech DevOps)

Evolução do MVP monolítico da Fase 1 para uma arquitetura de microsserviços
distribuídos, conteinerizados e orquestrados via Kubernetes (AWS EKS).

## Arquitetura

| Serviço | Linguagem | Porta | Dependências |
|---|---|---|---|
| `auth-service` | Go | 8001 | PostgreSQL |
| `flag-service` | Python/Flask | 8002 | PostgreSQL, auth-service |
| `targeting-service` | Python/Flask | 8003 | PostgreSQL, auth-service |
| `evaluation-service` | Go | 8004 | Redis, flag-service, targeting-service, SQS (opcional local) |
| `analytics-service` | Python/Flask | 8005 | SQS, DynamoDB |

Código-base dos 5 microsserviços fornecido pela FIAP para o Tech Challenge
Fase 2, adaptado com Dockerfile e orquestração pelo grupo.

## Rodando localmente

```bash
cp .env.example .env
# preencha AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN
# (credenciais da AWS Academy) e AWS_SQS_URL (fila real, não há SQS local)
docker compose up --build
```

Sobe 9 containers: os 5 microsserviços + auth-db, flags-db, targeting-db
(PostgreSQL), redis e dynamodb-local.

**Limitação conhecida:** o `analytics-service` cria o cliente boto3 sem
`endpoint_url` customizado, então mesmo com `dynamodb-local` rodando local,
as escritas de analytics vão para a tabela DynamoDB real da AWS, não para o
container local. Optamos por não alterar o código-fonte fornecido nesta fase.

## Infraestrutura AWS

Ver pasta [`infra/`](./infra) — provisionamento do cluster EKS (via `eksctl`,
usando a `LabRole` do AWS Academy) e dos recursos de dados (ECR, RDS,
ElastiCache, DynamoDB, SQS) via script AWS CLI.

```bash
eksctl create cluster -f infra/cluster.yaml
./infra/provision.sh
```

## Kubernetes

Ver pasta `k8s/` (em construção — Etapa 4 do desafio).

## Participantes

| Nome | RM | Discord |
|---|---|---|
| _preencher_ | _preencher_ | _preencher_ |
| _preencher_ | _preencher_ | _preencher_ |
| _preencher_ | _preencher_ | _preencher_ |
| _preencher_ | _preencher_ | _preencher_ |
| _preencher_ | _preencher_ | _preencher_ |
