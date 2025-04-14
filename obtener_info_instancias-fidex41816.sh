#!/bin/bash

# Lista de nombres de instancias (Tag:Name)
INSTANCES=(
  "FidexAppsProd2"
  "FidexAppsProd3"
  "FidexAppsProd4"
  "FidexAppsProd5"
  "FidexAppsProd7"
  "FidexAppsProd9"
  "FidexSopProd3"
  "FidexSopProd4"
  "FidexDBProd1"
)

# Archivo de salida
OUTPUT_FILE="info_instancias.json"
echo "[" > $OUTPUT_FILE

for NAME in "${INSTANCES[@]}"; do
  INSTANCE=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$NAME" \
    --query "Reservations[].Instances[]" \
    --output json)

  if [[ "$INSTANCE" == "[]" ]]; then
    echo "No se encontró la instancia: $NAME"
    continue
  fi

  INSTANCE_ID=$(echo "$INSTANCE" | jq -r '.[0].InstanceId // empty')
  PRIVATE_IP=$(echo "$INSTANCE" | jq -r '.[0].PrivateIpAddress // empty')
  PUBLIC_IP=$(echo "$INSTANCE" | jq -r '.[0].PublicIpAddress // empty')
  AMI_ID=$(echo "$INSTANCE" | jq -r '.[0].ImageId // empty')
  INSTANCE_TYPE=$(echo "$INSTANCE" | jq -r '.[0].InstanceType // empty')
  VPC_ID=$(echo "$INSTANCE" | jq -r '.[0].VpcId // empty')
  SUBNET_ID=$(echo "$INSTANCE" | jq -r '.[0].SubnetId // empty')
  CPU=$(echo "$INSTANCE" | jq -r '.[0].CpuOptions.CoreCount // empty')
  EBS_OPTIMIZED=$(echo "$INSTANCE" | jq -r '.[0].EbsOptimized // false')

  EIP=$(aws ec2 describe-addresses --filters "Name=instance-id,Values=$INSTANCE_ID" \
    --query "Addresses[0].PublicIp" --output text 2>/dev/null)

  [[ "$EIP" == "None" || -z "$EIP" ]] && EIP=null || EIP="\"$EIP\""
  [[ -z "$PRIVATE_IP" ]] && PRIVATE_IP=null || PRIVATE_IP="\"$PRIVATE_IP\""
  [[ -z "$PUBLIC_IP" ]] && PUBLIC_IP=null || PUBLIC_IP="\"$PUBLIC_IP\""
  [[ -z "$AMI_ID" ]] && AMI_ID=null || AMI_ID="\"$AMI_ID\""
  [[ -z "$VPC_ID" ]] && VPC_ID=null || VPC_ID="\"$VPC_ID\""
  [[ -z "$SUBNET_ID" ]] && SUBNET_ID=null || SUBNET_ID="\"$SUBNET_ID\""
  [[ -z "$CPU" ]] && CPU=null
  [[ -z "$INSTANCE_TYPE" ]] && FAMILY=null || FAMILY="\"$(cut -d. -f1 <<< "$INSTANCE_TYPE")\""

  VOLUMES=$(aws ec2 describe-volumes \
    --filters Name=attachment.instance-id,Values=$INSTANCE_ID \
    --query 'Volumes[].VolumeId' --output json)

  # Crear entrada JSON
  echo "{
    \"nombre_instancia\": \"$NAME\",
    \"ip_privada\": $PRIVATE_IP,
    \"ip_publica\": $PUBLIC_IP,
    \"elastic_ip\": $EIP,
    \"ami\": $AMI_ID,
    \"vpc\": $VPC_ID,
    \"subnet\": $SUBNET_ID,
    \"cpu\": $CPU,
    \"ebs_optimizado\": $EBS_OPTIMIZED,
    \"familia_instancia\": $FAMILY,
    \"discos\": $VOLUMES,
    \"software_licenciado_por_cpu\": null
  }" >> $OUTPUT_FILE

  # Añadir coma entre objetos JSON excepto el último
  if [[ "$NAME" != "${INSTANCES[-1]}" ]]; then
    echo "," >> $OUTPUT_FILE
  fi
done

echo "]" >> $OUTPUT_FILE

echo "✅ Archivo generado: $OUTPUT_FILE"
