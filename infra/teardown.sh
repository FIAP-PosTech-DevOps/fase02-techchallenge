#!/usr/bin/env bash
#
# infra/teardown.sh
#
# Remove os recursos criados por provision.sh. Rode isso no fim do dia de
# testes para não deixar RDS/ElastiCache ligados consumindo o crédito da
# AWS Academy (esses dois são os que mais custam e geralmente não têm
# free tier no Academy).
#
# Uso: ./infra/teardown.sh

set -euo pipefail
REGION="us-east-1"

echo "### Removendo instâncias RDS ###"
for db in auth-db flag-db targeting-db; do
  aws rds delete-db-instance --db-instance-identifier "$db" \
    --skip-final-snapshot --region "$REGION" >/dev/null 2>&1 \
    && echo "  [ok] $db removendo..." || echo "  [skip] $db não existe."
done

echo "### Removendo cluster ElastiCache ###"
aws elasticache delete-cache-cluster --cache-cluster-id togglemaster-redis \
  --region "$REGION" >/dev/null 2>&1 \
  && echo "  [ok] togglemaster-redis removendo..." || echo "  [skip] não existe."

echo "### Removendo tabela DynamoDB ###"
aws dynamodb delete-table --table-name ToggleMasterAnalytics \
  --region "$REGION" >/dev/null 2>&1 \
  && echo "  [ok] tabela removida." || echo "  [skip] não existe."

echo "### Removendo fila SQS ###"
QUEUE_URL=$(aws sqs get-queue-url --queue-name togglemaster-events --region "$REGION" --query 'QueueUrl' --output text 2>/dev/null || echo "")
if [ -n "$QUEUE_URL" ]; then
  aws sqs delete-queue --queue-url "$QUEUE_URL" --region "$REGION" >/dev/null
  echo "  [ok] fila removida."
else
  echo "  [skip] fila não existe."
fi

echo ""
echo "Nota: os repositórios ECR NÃO são removidos automaticamente (são baratos"
echo "e você provavelmente ainda vai precisar deles). Remova manualmente com"
echo "'aws ecr delete-repository --repository-name <nome> --force' se quiser."
echo ""
echo "Nota: o cluster EKS criado via eksctl (infra/cluster.yaml) tem custo"
echo "significativo (control plane + nodes). Remova com:"
echo "  eksctl delete cluster -f infra/cluster.yaml"
