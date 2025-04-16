
#!/bin/bash

INSTANCE_ID="i-0e4d1937f5bb18510"
REGION="us-west-2"

echo "🔐 Enviando comando para cambiar contraseñas de usuarios..."

COMMAND_ID=$(aws ssm send-command \
  --document-name "AWS-RunPowerShellScript" \
  --instance-ids "$INSTANCE_ID" \
  --comment "Resetear contraseñas usuarios Windows y forzar cambio en próximo login" \
  --parameters commands='
    net user fidex-adm C0ntr4Adm2025! /logonpasswordchg:yes;
    net user Administrator Adm1n!2025# /logonpasswordchg:yes;' \
  --timeout-seconds 60 \
  --region "$REGION" \
  --query "Command.CommandId" \
  --output text)

echo "✅ Comando enviado. CommandId: $COMMAND_ID"
echo "⏳ Esperando 10 segundos para permitir ejecución remota..."
sleep 10

echo "📥 Consultando resultado..."
aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --region "$REGION" \
  --output json > resultado_comando_ssm.json

echo "📄 Resultado guardado en resultado_comando_ssm.json"
