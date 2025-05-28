
#!/bin/bash

INSTANCE_ID=$1
REGION="us-east-1"

if [ -z "$INSTANCE_ID" ]; then
  echo "❌ Debes proporcionar un Instance ID. Ejemplo:"
  echo "./verificar_problema_ec2.sh i-xxxxxxxxxxxxxxxxx"
  exit 1
fi

echo "🔍 Verificando estado general de la instancia $INSTANCE_ID..."

# Obtener estado de instancia
aws ec2 describe-instance-status \
  --instance-id "$INSTANCE_ID" \
  --include-all-instances \
  --region "$REGION" \
  --output json > status_$INSTANCE_ID.json

echo "✅ Estado guardado en: status_$INSTANCE_ID.json"

# Obtener información de límites (vCPU, instancias R5, etc.)
echo "📊 Verificando límites de servicio EC2..."

aws service-quotas list-service-quotas \
  --service-code ec2 \
  --region "$REGION" \
  --output json > ec2_limits_$REGION.json

echo "✅ Límites guardados en: ec2_limits_$REGION.json"

# Obtener logs del sistema (si está disponible)
echo "📄 Descargando log de sistema..."

aws ec2 get-console-output \
  --instance-id "$INSTANCE_ID" \
  --region "$REGION" \
  --output text > system_log_$INSTANCE_ID.txt

echo "✅ Log guardado en: system_log_$INSTANCE_ID.txt"

echo ""
echo "🧾 Revisa los archivos generados para detectar errores:"
echo "- status_$INSTANCE_ID.json (status de hardware y sistema)"
echo "- ec2_limits_$REGION.json (límites de cuenta EC2)"
echo "- system_log_$INSTANCE_ID.txt (log de arranque de la instancia)"
