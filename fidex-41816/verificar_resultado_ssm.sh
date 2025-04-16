
#!/bin/bash

# Reemplazar con el CommandId real (puede pasarse como argumento también)
COMMAND_ID="$1"
INSTANCE_ID="i-0e4d1937f5bb18510"
REGION="us-west-2"

if [ -z "$COMMAND_ID" ]; then
  echo "❌ Debes proporcionar el CommandId como argumento"
  echo "Uso: ./verificar_resultado_ssm.sh <command-id>"
  exit 1
fi

echo "🔍 Consultando resultado del comando $COMMAND_ID para la instancia $INSTANCE_ID..."

aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --region "$REGION" \
  --output json > resultado_comando_ssm.json

echo "✅ Resultado guardado en resultado_comando_ssm.json"
