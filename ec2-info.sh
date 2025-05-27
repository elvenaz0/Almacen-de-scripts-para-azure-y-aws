#!/bin/sh
# Script para recopilar informacion de EC2 en todas las regiones disponibles
# y almacenarla en un unico archivo JSON.
# Debe ejecutarse en AWS CloudShell o en un entorno con AWS CLI y jq instalados.

set -e

OUTPUT_FILE="ec2-info.json"
TMP_DIR=$(mktemp -d)

# Obtener listado de regiones disponibles
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# Crear archivo JSON vacio
echo '{}' > "$OUTPUT_FILE"

for REGION in $REGIONS; do
    echo "Recolectando informacion de EC2 en la region: $REGION"

    # Consultas de AWS CLI para la region
    aws ec2 describe-instances --region "$REGION" --output json > "$TMP_DIR/instances.json"
    aws ec2 describe-volumes --region "$REGION" --output json > "$TMP_DIR/volumes.json"
    aws ec2 describe-snapshots --region "$REGION" --owner-ids self --output json > "$TMP_DIR/snapshots.json"
    aws ec2 describe-security-groups --region "$REGION" --output json > "$TMP_DIR/secgroups.json"
    aws ec2 describe-key-pairs --region "$REGION" --output json > "$TMP_DIR/keypairs.json"
    aws ec2 describe-images --region "$REGION" --owners self --output json > "$TMP_DIR/images.json"
    aws ec2 describe-addresses --region "$REGION" --output json > "$TMP_DIR/addresses.json"
    aws elbv2 describe-target-groups --region "$REGION" --output json > "$TMP_DIR/targetgroups.json"
    aws ec2 describe-spot-instance-requests --region "$REGION" --output json > "$TMP_DIR/spotrequests.json" 2>/dev/null || echo '[]' > "$TMP_DIR/spotrequests.json"

    # Construir objeto JSON para la region
    jq -n \
        --slurpfile instances "$TMP_DIR/instances.json" \
        --slurpfile volumes "$TMP_DIR/volumes.json" \
        --slurpfile snapshots "$TMP_DIR/snapshots.json" \
        --slurpfile secgroups "$TMP_DIR/secgroups.json" \
        --slurpfile keypairs "$TMP_DIR/keypairs.json" \
        --slurpfile images "$TMP_DIR/images.json" \
        --slurpfile addresses "$TMP_DIR/addresses.json" \
        --slurpfile targetgroups "$TMP_DIR/targetgroups.json" \
        --slurpfile spotrequests "$TMP_DIR/spotrequests.json" \
        '{
            instances: $instances[0],
            volumes: $volumes[0],
            snapshots: $snapshots[0],
            security_groups: $secgroups[0],
            key_pairs: $keypairs[0],
            images: $images[0],
            addresses: $addresses[0],
            target_groups: $targetgroups[0],
            spot_instance_requests: $spotrequests[0]
        }' > "$TMP_DIR/region.json"

    # Agregar los datos de la region al archivo final
    jq --arg region "$REGION" --slurpfile data "$TMP_DIR/region.json" \
       '. + {($region): $data[0]}' "$OUTPUT_FILE" > "$TMP_DIR/tmp.json" && mv "$TMP_DIR/tmp.json" "$OUTPUT_FILE"

done

rm -rf "$TMP_DIR"
echo "Informacion almacenada en $OUTPUT_FILE"
