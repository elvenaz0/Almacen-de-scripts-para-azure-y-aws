#!/bin/bash

# Script para resize de instancias desde archivo JSON
# Requiere: jq, AWS CLI configurado y permisos suficientes

INPUT_JSON="instancias_recomendadas.json"
LOG_FILE="resize_json_based.log"
CHECKPOINT_FILE=".resize_checkpoints_json"

touch "$CHECKPOINT_FILE"
echo "--- Inicio: $(date) ---" >> "$LOG_FILE"

total=$(jq length "$INPUT_JSON")

for i in $(seq 0 $(($total - 1))); do
  nombre=$(jq -r ".[$i].nombre" "$INPUT_JSON")
  tipo=$(jq -r ".[$i].tipo_recomendado" "$INPUT_JSON")

  if grep -q "^$nombre$" "$CHECKPOINT_FILE"; then
    echo "⏩ $nombre ya fue procesada, omitiendo..." | tee -a "$LOG_FILE"
    continue
  fi

  echo "--- Procesando $nombre ---" | tee -a "$LOG_FILE"
  INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$nombre" --query "Reservations[].Instances[].InstanceId" --output text)

  if [ -z "$INSTANCE_ID" ]; then
    echo "❌ No se encontró $nombre" | tee -a "$LOG_FILE"
    exit 1
  fi

  echo "⏹️  Deteniendo $INSTANCE_ID..." | tee -a "$LOG_FILE"
  aws ec2 stop-instances --instance-ids "$INSTANCE_ID" | tee -a "$LOG_FILE"
  aws ec2 wait instance-stopped --instance-ids "$INSTANCE_ID"

  echo "🔧 Cambiando tipo a $tipo..." | tee -a "$LOG_FILE"
  aws ec2 modify-instance-attribute --instance-id "$INSTANCE_ID" --instance-type "{\"Value\": \"$tipo\"}" | tee -a "$LOG_FILE"

  echo "🚀 Iniciando $INSTANCE_ID..." | tee -a "$LOG_FILE"
  aws ec2 start-instances --instance-ids "$INSTANCE_ID" | tee -a "$LOG_FILE"
  aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

  echo "✅ $nombre redimensionada correctamente a $tipo" | tee -a "$LOG_FILE"
  echo "$nombre" >> "$CHECKPOINT_FILE"
done

echo "✅ Todas las instancias fueron procesadas." | tee -a "$LOG_FILE"
