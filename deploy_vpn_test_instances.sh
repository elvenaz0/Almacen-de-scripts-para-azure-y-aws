
#!/bin/bash

# VARIABLES: ajusta según tu región y configuración
AMI_ID="ami-0c02fb55956c7d316"  # Amazon Linux 2 (us-east-1), cámbialo si estás en otra región
INSTANCE_TYPE="t2.micro"
VPC_ID="<TU_VPC_ID>"
SUBNET_ID="<TU_SUBNET_ID>"
SG_ID="<TU_SECURITY_GROUP_ID>"
KEY_NAME="<TU_NOMBRE_DE_LA_LLAVE>"

# Direcciones IP privadas a usar
IP1="10.130.12.10"
IP2="10.130.12.11"

echo "Lanzando primera instancia en ${IP1}..."
aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --count 1 \
  --instance-type "$INSTANCE_TYPE" \
  --subnet-id "$SUBNET_ID" \
  --private-ip-address "$IP1" \
  --security-group-ids "$SG_ID" \
  --key-name "$KEY_NAME" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=VPN-Test-Instance-1}]'

echo "Lanzando segunda instancia en ${IP2}..."
aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --count 1 \
  --instance-type "$INSTANCE_TYPE" \
  --subnet-id "$SUBNET_ID" \
  --private-ip-address "$IP2" \
  --security-group-ids "$SG_ID" \
  --key-name "$KEY_NAME" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=VPN-Test-Instance-2}]'

# Reglas del SG para permitir ICMP (ping) y HTTP opcionalmente
echo "Abriendo ICMP (ping) en el Security Group..."
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol icmp \
  --port -1 \
  --cidr 0.0.0.0/0

echo "Abriendo puerto 80 (HTTP) en el Security Group..."
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

echo "Listo. Las instancias están lanzadas con IPs privadas ${IP1} y ${IP2}."
