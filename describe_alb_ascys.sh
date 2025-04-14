
#!/bin/bash

# Nombre del ALB (cambia si lo crearon con otro nombre real)
ALB_NAME="ALB-ASCys-FTP"

echo "Obteniendo información del Load Balancer con nombre: $ALB_NAME"
ALB_ARN=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName, '$ALB_NAME')].LoadBalancerArn" --output text)

echo "ARN del Load Balancer: $ALB_ARN"

echo ""
echo "Obteniendo listeners del ALB..."
LISTENER_ARNS=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --query "Listeners[*].ListenerArn" --output text)

for LISTENER_ARN in $LISTENER_ARNS; do
  echo ""
  echo "Detalles del listener: $LISTENER_ARN"
  aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --output json
done

echo ""
echo "Obteniendo Target Groups asociados..."
TARGET_GROUPS=$(aws elbv2 describe-target-groups --load-balancer-arn "$ALB_ARN" --query "TargetGroups[*].TargetGroupArn" --output text)

for TG_ARN in $TARGET_GROUPS; do
  echo ""
  echo "Target Group: $TG_ARN"
  echo "Instancias registradas:"
  aws elbv2 describe-target-health --target-group-arn "$TG_ARN" --output json
done
