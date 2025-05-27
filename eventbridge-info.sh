#!/bin/sh
# Script para recopilar informacion de reglas de EventBridge en todas las regiones disponibles
# y almacenarla en un archivo JSON.
# Debe ejecutarse en AWS CloudShell o en un entorno con AWS CLI y jq instalados.

set -e

OUTPUT_FILE="eventbridge-rules.json"
TMP_DIR=$(mktemp -d)

# Obtener listado de regiones disponibles
REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

# Crear archivo JSON vacio
echo '{}' > "$OUTPUT_FILE"

for REGION in $REGIONS; do
    echo "Recolectando reglas de EventBridge en la region: $REGION"

    RULE_NAMES=$(aws events list-rules --region "$REGION" --query 'Rules[].Name' --output text)
    RULE_FILES=""

    for RULE in $RULE_NAMES; do
        echo "  Procesando regla: $RULE"
        aws events describe-rule --name "$RULE" --region "$REGION" --output json > "$TMP_DIR/rule.json"
        aws events list-targets-by-rule --rule "$RULE" --region "$REGION" --output json > "$TMP_DIR/targets.json"

        jq -n \
            --slurpfile rule "$TMP_DIR/rule.json" \
            --slurpfile targets "$TMP_DIR/targets.json" \
            '{rule: $rule[0], targets: $targets[0].Targets}' > "$TMP_DIR/${RULE}.json"
        RULE_FILES="$RULE_FILES $TMP_DIR/${RULE}.json"
    done

    if [ -n "$RULE_FILES" ]; then
        jq -s '.' $RULE_FILES > "$TMP_DIR/rules.json"
    else
        echo '[]' > "$TMP_DIR/rules.json"
    fi

    jq --arg region "$REGION" --slurpfile data "$TMP_DIR/rules.json" \
       '. + {($region): $data[0]}' "$OUTPUT_FILE" > "$TMP_DIR/tmp.json" && mv "$TMP_DIR/tmp.json" "$OUTPUT_FILE"

    rm -f $RULE_FILES "$TMP_DIR/rules.json" "$TMP_DIR/rule.json" "$TMP_DIR/targets.json"
done

rm -rf "$TMP_DIR"
echo "Informacion almacenada en $OUTPUT_FILE"
