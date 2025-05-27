#!/bin/sh
# Script para recopilar informacion de redes de AWS (VPC, VPN, security groups,
# tablas de ruteo, etc.) en todas las regiones y generar una salida unificada.
# Produce un archivo JSON agrupado por servicio y un resumen en Markdown.
# Debe ejecutarse en AWS CloudShell o en un entorno con AWS CLI y jq instalados.

set -e

OUTPUT_JSON="network-info.json"
OUTPUT_MD="network-info.md"
ERROR_LOG="error.log"
TMP_DIR=$(mktemp -d)

command -v aws >/dev/null 2>&1 || { echo "aws CLI no encontrado. Saliendo." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq no encontrado. Saliendo." >&2; exit 1; }

[ -f "$OUTPUT_JSON" ] && cp "$OUTPUT_JSON" "${OUTPUT_JSON}.bak"
[ -f "$OUTPUT_MD" ] && cp "$OUTPUT_MD" "${OUTPUT_MD}.bak"
[ -f "$ERROR_LOG" ] && rm "$ERROR_LOG"

REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

cat <<EOJ > "$OUTPUT_JSON"
{
  "vpcs": [],
  "subnets": [],
  "route_tables": [],
  "security_groups": [],
  "network_acls": [],
  "internet_gateways": [],
  "nat_gateways": [],
  "vpn_connections": [],
  "vpn_gateways": [],
  "customer_gateways": [],
  "transit_gateways": [],
  "network_interfaces": []
}
EOJ

echo "# Resumen de Red AWS" > "$OUTPUT_MD"
echo "" >> "$OUTPUT_MD"
echo "**Fecha:** $(date)" >> "$OUTPUT_MD"
echo "" >> "$OUTPUT_MD"

for REGION in $REGIONS; do
    echo "Recolectando informacion en: $REGION"
    echo "## Región: $REGION" >> "$OUTPUT_MD"

    aws ec2 describe-vpcs --region "$REGION" --output json > "$TMP_DIR/vpcs.json" 2>>"$ERROR_LOG"
    aws ec2 describe-subnets --region "$REGION" --output json > "$TMP_DIR/subnets.json" 2>>"$ERROR_LOG"
    aws ec2 describe-route-tables --region "$REGION" --output json > "$TMP_DIR/route_tables.json" 2>>"$ERROR_LOG"
    aws ec2 describe-security-groups --region "$REGION" --output json > "$TMP_DIR/security_groups.json" 2>>"$ERROR_LOG"
    aws ec2 describe-network-acls --region "$REGION" --output json > "$TMP_DIR/network_acls.json" 2>>"$ERROR_LOG"
    aws ec2 describe-internet-gateways --region "$REGION" --output json > "$TMP_DIR/internet_gateways.json" 2>>"$ERROR_LOG"
    aws ec2 describe-nat-gateways --region "$REGION" --output json > "$TMP_DIR/nat_gateways.json" 2>>"$ERROR_LOG" || echo '[]' > "$TMP_DIR/nat_gateways.json"
    aws ec2 describe-vpn-connections --region "$REGION" --output json > "$TMP_DIR/vpn_connections.json" 2>>"$ERROR_LOG" || echo '[]' > "$TMP_DIR/vpn_connections.json"
    aws ec2 describe-vpn-gateways --region "$REGION" --output json > "$TMP_DIR/vpn_gateways.json" 2>>"$ERROR_LOG" || echo '[]' > "$TMP_DIR/vpn_gateways.json"
    aws ec2 describe-customer-gateways --region "$REGION" --output json > "$TMP_DIR/customer_gateways.json" 2>>"$ERROR_LOG" || echo '[]' > "$TMP_DIR/customer_gateways.json"
    aws ec2 describe-transit-gateways --region "$REGION" --output json > "$TMP_DIR/transit_gateways.json" 2>>"$ERROR_LOG" || echo '[]' > "$TMP_DIR/transit_gateways.json"
    aws ec2 describe-network-interfaces --region "$REGION" --output json > "$TMP_DIR/network_interfaces.json" 2>>"$ERROR_LOG"

    jq \
        --arg region "$REGION" \
        --slurpfile vpcs "$TMP_DIR/vpcs.json" \
        --slurpfile subnets "$TMP_DIR/subnets.json" \
        --slurpfile route_tables "$TMP_DIR/route_tables.json" \
        --slurpfile security_groups "$TMP_DIR/security_groups.json" \
        --slurpfile network_acls "$TMP_DIR/network_acls.json" \
        --slurpfile internet_gateways "$TMP_DIR/internet_gateways.json" \
        --slurpfile nat_gateways "$TMP_DIR/nat_gateways.json" \
        --slurpfile vpn_connections "$TMP_DIR/vpn_connections.json" \
        --slurpfile vpn_gateways "$TMP_DIR/vpn_gateways.json" \
        --slurpfile customer_gateways "$TMP_DIR/customer_gateways.json" \
        --slurpfile transit_gateways "$TMP_DIR/transit_gateways.json" \
        --slurpfile network_interfaces "$TMP_DIR/network_interfaces.json" \
        '.vpcs += ($vpcs[0].Vpcs | map(. + {region: $region})) |
         .subnets += ($subnets[0].Subnets | map(. + {region: $region})) |
         .route_tables += ($route_tables[0].RouteTables | map(. + {region: $region})) |
         .security_groups += ($security_groups[0].SecurityGroups | map(. + {region: $region})) |
         .network_acls += ($network_acls[0].NetworkAcls | map(. + {region: $region})) |
         .internet_gateways += ($internet_gateways[0].InternetGateways | map(. + {region: $region})) |
         .nat_gateways += ($nat_gateways[0].NatGateways | map(. + {region: $region})) |
         .vpn_connections += ($vpn_connections[0].VpnConnections | map(. + {region: $region})) |
         .vpn_gateways += ($vpn_gateways[0].VpnGateways | map(. + {region: $region})) |
         .customer_gateways += ($customer_gateways[0].CustomerGateways | map(. + {region: $region})) |
         .transit_gateways += ($transit_gateways[0].TransitGateways | map(. + {region: $region})) |
         .network_interfaces += ($network_interfaces[0].NetworkInterfaces | map(. + {region: $region}))' \
         "$OUTPUT_JSON" > "$TMP_DIR/tmp.json" && mv "$TMP_DIR/tmp.json" "$OUTPUT_JSON"

    echo "- VPCs: $(jq '.Vpcs | length' "$TMP_DIR/vpcs.json")" >> "$OUTPUT_MD"
    echo "- Subnets: $(jq '.Subnets | length' "$TMP_DIR/subnets.json")" >> "$OUTPUT_MD"
    echo "- Route Tables: $(jq '.RouteTables | length' "$TMP_DIR/route_tables.json")" >> "$OUTPUT_MD"
    echo "- Security Groups: $(jq '.SecurityGroups | length' "$TMP_DIR/security_groups.json")" >> "$OUTPUT_MD"
    echo "- Internet Gateways: $(jq '.InternetGateways | length' "$TMP_DIR/internet_gateways.json")" >> "$OUTPUT_MD"
    echo "- NAT Gateways: $(jq '.NatGateways | length' "$TMP_DIR/nat_gateways.json")" >> "$OUTPUT_MD"
    echo "- VPN Connections: $(jq '.VpnConnections | length' "$TMP_DIR/vpn_connections.json")" >> "$OUTPUT_MD"
    echo "- Transit Gateways: $(jq '.TransitGateways | length' "$TMP_DIR/transit_gateways.json")" >> "$OUTPUT_MD"
    echo "- Network Interfaces: $(jq '.NetworkInterfaces | length' "$TMP_DIR/network_interfaces.json")" >> "$OUTPUT_MD"
    echo "" >> "$OUTPUT_MD"

done

gzip -f "$OUTPUT_JSON"
rm -rf "$TMP_DIR"
echo "✓ Informacion almacenada en ${OUTPUT_JSON}.gz y resumen en $OUTPUT_MD"
echo "✓ Errores (si hubo) registrados en $ERROR_LOG"
