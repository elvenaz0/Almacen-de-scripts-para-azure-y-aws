
#!/bin/bash

# === CONFIGURACIÓN ===
ALB_NAME="ALB-ASCys-FTP"
SG_IDS=("sg-8d678bf6" "sg-0ce148df5793a8a0e")
OUTPUT_FILE="verificacion_alb_sg_output.json"

# Crear archivo JSON
echo "{" > $OUTPUT_FILE

# === 1. Información del ALB ===
echo "\"alb_info\":" >> $OUTPUT_FILE
ALB_ARN=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, '$ALB_NAME')].LoadBalancerArn" --output text)
aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" --output json >> $OUTPUT_FILE
echo "," >> $OUTPUT_FILE

# === 2. Listeners y reglas del ALB ===
echo "\"alb_listeners_and_rules\":" >> $OUTPUT_FILE
LISTENER_ARNS=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --query "Listeners[*].ListenerArn" --output text)

echo "[" >> $OUTPUT_FILE
for LISTENER_ARN in $LISTENER_ARNS; do
  aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --output json
  echo ","  # Agrega coma entre elementos
done | sed '$ s/,$//' >> $OUTPUT_FILE
echo "]," >> $OUTPUT_FILE

# === 3. Target Groups asociados ===
echo "\"target_groups\":" >> $OUTPUT_FILE
TG_ARNS=$(aws elbv2 describe-target-groups --load-balancer-arn "$ALB_ARN" --query "TargetGroups[*].TargetGroupArn" --output text)

echo "[" >> $OUTPUT_FILE
for TG_ARN in $TG_ARNS; do
  aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --output json
  echo ","
done | sed '$ s/,$//' >> $OUTPUT_FILE
echo "]," >> $OUTPUT_FILE

# === 4. Reglas completas en formato JSON ===
echo "\"security_group_rules_full\":" >> $OUTPUT_FILE
aws ec2 describe-security-groups --group-ids "${SG_IDS[@]}" --query 'SecurityGroups[*].IpPermissions' --output json >> $OUTPUT_FILE
echo "," >> $OUTPUT_FILE

# === 5. Reglas simplificadas (puertos y CIDRs) en tabla ===
echo "\"security_group_rules_summary\":" >> $OUTPUT_FILE
aws ec2 describe-security-groups --group-ids "${SG_IDS[@]}" --query 'SecurityGroups[*].IpPermissions[*].{From:FromPort,To:ToPort,CIDR:IpRanges[*].CidrIp}' --output json >> $OUTPUT_FILE

echo "}" >> $OUTPUT_FILE

echo "✅ Archivo de salida generado: $OUTPUT_FILE"
