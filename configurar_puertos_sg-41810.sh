
#!/bin/bash

# IDs de Security Groups asociados a la instancia 172.31.1.225
SG_IDS=("sg-8d678bf6" "sg-0ce148df5793a8a0e")

# Regla: Puerto 10300 - acceso externo
# Regla: Puerto 10301 - acceso externo
# Regla: Puerto 10204 - acceso específico desde 10.91.49.59

for SG_ID in "${SG_IDS[@]}"; do
  echo "Aplicando reglas en el Security Group: $SG_ID"

  echo "Abrir puerto 10300 desde 0.0.0.0/0"
  aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 10300 --cidr 0.0.0.0/0 || echo "Regla ya existe o error"

  echo "Abrir puerto 10301 desde 0.0.0.0/0"
  aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 10301 --cidr 0.0.0.0/0 || echo "Regla ya existe o error"

  echo "Abrir puerto 10204 solo desde 10.91.49.59"
  aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 10204 --cidr 10.91.49.59/32 || echo "Regla ya existe o error"

done

echo "Listo. Las reglas fueron aplicadas."
