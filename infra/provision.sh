#!/usr/bin/env bash
#
# infra/provision.sh
#
# Provisiona toda a infraestrutura de dados do ToggleMaster (Fase 2) via AWS CLI:
#   - 5 repositórios ECR
#   - 3 instâncias RDS PostgreSQL (auth, flag, targeting)
#   - 1 cluster ElastiCache Redis (evaluation)
#   - 1 tabela DynamoDB (analytics)
#   - 1 fila SQS (evaluation -> analytics)
#
# Pré-requisitos:
#   - aws cli configurado (aws configure) com credenciais do AWS Academy
#   - Rodar de dentro do ambiente do Academy (LabRole já existe por padrão)
#
# Uso:
#   chmod +x infra/provision.sh
#   ./infra/provision.sh
#
# Idempotência: o script verifica se cada recurso já existe antes de criar,
# então pode ser rodado de novo com segurança (ex: depois de um erro no meio).

set -euo pipefail

REGION="us-east-1"
DB_USER="toggle_admin"
DB_PASSWORD="TrocarSenhaForte123!"   # troque antes de rodar em grupo
DB_INSTANCE_CLASS="db.t3.micro"
REDIS_NODE_TYPE="cache.t3.micro"

# Descobre automaticamente o Security Group e Subnet Group default da VPC padrão
VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' --output text --region "$REGION")
SG_ID=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values="$VPC_ID" Name=group-name,Values=default \
  --query 'SecurityGroups[0].GroupId' --output text --region "$REGION")

echo "VPC padrão: $VPC_ID | Security Group: $SG_ID"
echo "=================================================="

# --- 1. ECR: 5 repositórios ---
echo ""
echo "### ECR ###"
for repo in auth-service flag-service targeting-service evaluation-service analytics-service; do
  if aws ecr describe-repositories --repository-names "$repo" --region "$REGION" >/dev/null 2>&1; then
    echo "  [skip] Repositório $repo já existe."
  else
    aws ecr create-repository --repository-name "$repo" --region "$REGION" >/dev/null
    echo "  [ok]   Repositório $repo criado."
  fi
done

# --- 2. RDS: 3 instâncias PostgreSQL ---
echo ""
echo "### RDS ###"
for db in auth-db flag-db targeting-db; do
  if aws rds describe-db-instances --db-instance-identifier "$db" --region "$REGION" >/dev/null 2>&1; then
    echo "  [skip] Instância RDS $db já existe."
  else
    aws rds create-db-instance \
      --db-instance-identifier "$db" \
      --db-instance-class "$DB_INSTANCE_CLASS" \
      --engine postgres \
      --master-username "$DB_USER" \
      --master-user-password "$DB_PASSWORD" \
      --allocated-storage 20 \
      --vpc-security-group-ids "$SG_ID" \
      --publicly-accessible \
      --region "$REGION" >/dev/null
    echo "  [ok]   Criação de $db iniciada (leva alguns minutos para ficar 'available')."
  fi
done

# --- 3. ElastiCache: 1 cluster Redis ---
echo ""
echo "### ElastiCache (Redis) ###"
if aws elasticache describe-cache-clusters --cache-cluster-id togglemaster-redis --region "$REGION" >/dev/null 2>&1; then
  echo "  [skip] Cluster Redis togglemaster-redis já existe."
else
  aws elasticache create-cache-cluster \
    --cache-cluster-id togglemaster-redis \
    --engine redis \
    --cache-node-type "$REDIS_NODE_TYPE" \
    --num-cache-nodes 1 \
    --security-group-ids "$SG_ID" \
    --region "$REGION" >/dev/null
  echo "  [ok]   Criação do cluster Redis iniciada."
fi

# --- 4. DynamoDB: 1 tabela ---
echo ""
echo "### DynamoDB ###"
if aws dynamodb describe-table --table-name ToggleMasterAnalytics --region "$REGION" >/dev/null 2>&1; then
  echo "  [skip] Tabela ToggleMasterAnalytics já existe."
else
  aws dynamodb create-table \
    --table-name ToggleMasterAnalytics \
    --attribute-definitions AttributeName=event_id,AttributeType=S \
    --key-schema AttributeName=event_id,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --region "$REGION" >/dev/null
  echo "  [ok]   Tabela ToggleMasterAnalytics criada."
fi

# --- 5. SQS: 1 fila ---
echo ""
echo "### SQS ###"
if aws sqs get-queue-url --queue-name togglemaster-events --region "$REGION" >/dev/null 2>&1; then
  echo "  [skip] Fila togglemaster-events já existe."
else
  aws sqs create-queue --queue-name togglemaster-events --region "$REGION" >/dev/null
  echo "  [ok]   Fila togglemaster-events criada."
fi

echo ""
echo "=================================================="
echo "Provisionamento concluído. Coletando endpoints..."
echo "=================================================="

echo ""
echo "### Endpoints RDS (podem levar minutos para ficar 'available') ###"
for db in auth-db flag-db targeting-db; do
  ENDPOINT=$(aws rds describe-db-instances --db-instance-identifier "$db" \
    --query 'DBInstances[0].Endpoint.Address' --output text --region "$REGION" 2>/dev/null || echo "pendente")
  echo "  $db -> $ENDPOINT"
done

echo ""
echo "### Endpoint ElastiCache ###"
aws elasticache describe-cache-clusters --cache-cluster-id togglemaster-redis --show-cache-node-info \
  --query 'CacheClusters[0].CacheNodes[0].Endpoint.Address' --output text --region "$REGION" 2>/dev/null || echo "  pendente"

echo ""
echo "### URL da fila SQS ###"
aws sqs get-queue-url --queue-name togglemaster-events --region "$REGION" --query 'QueueUrl' --output text

echo ""
echo "### URIs dos repositórios ECR ###"
aws ecr describe-repositories --region "$REGION" \
  --query 'repositories[?starts_with(repositoryName, `auth-service`) || starts_with(repositoryName, `flag-service`) || starts_with(repositoryName, `targeting-service`) || starts_with(repositoryName, `evaluation-service`) || starts_with(repositoryName, `analytics-service`)].[repositoryName,repositoryUri]' \
  --output table

echo ""
echo "Guarde esses valores: eles vão para os Secrets/ConfigMaps do Kubernetes na Etapa 3."
