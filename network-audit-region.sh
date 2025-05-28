#!/bin/sh
# Script que recopila informacion de redes de AWS en cada region y produce un
# reporte JSON agrupado por region y un resumen en Markdown.
# Debe ejecutarse en un entorno con AWS CLI y jq instalados.

set -e

OUTPUT_JSON="network-report.json"
OUTPUT_MD="network-report.md"
ERROR_LOG="error.log"
TMP_DIR=$(mktemp -d)

# Verificar dependencias
command -v aws >/dev/null 2>&1 || { echo "aws CLI no encontrado. Saliendo." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq no encontrado. Saliendo." >&2; exit 1; }

# Respaldos de archivos previos
[ -f "$OUTPUT_JSON" ] && cp "$OUTPUT_JSON" "${OUTPUT_JSON}.bak"
[ -f "$OUTPUT_MD" ] && cp "$OUTPUT_MD" "${OUTPUT_MD}.bak"
[ -f "$ERROR_LOG" ] && rm "$ERROR_LOG"

echo '{}' > "$OUTPUT_JSON"

REGIONS=$(aws ec2 describe-regions --query "Regions[].RegionName" --output text)

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
    aws ec2 describe-network-acls --region "$REGION" --output json > "$TMP_DIR/network_acls.json" 2>>"$ERROR_LOG"
    aws ec2 describe-security-groups --region "$REGION" --output json > "$TMP_DIR/security_groups.json" 2>>"$ERROR_LOG"
    aws ec2 describe-network-interfaces --region "$REGION" --output json > "$TMP_DIR/network_interfaces.json" 2>>"$ERROR_LOG"
    aws ec2 describe-internet-gateways --region "$REGION" --output json > "$TMP_DIR/internet_gateways.json" 2>>"$ERROR_LOG"
    aws ec2 describe-nat-gateways --region "$REGION" --output json > "$TMP_DIR/nat_gateways.json" 2>>"$ERROR_LOG" || echo '[]' > "$TMP_DIR/nat_gateways.json"
    aws ec2 describe-vpn-connections --region "$REGION" --output json > "$TMP_DIR/vpn_connections.json" 2>>"$ERROR_LOG" || echo '[]' > "$TMP_DIR/vpn_connections.json"
    aws ec2 describe-vpn-gateways --region "$REGION" --output json > "$TMP_DIR/vpn_gateways.json" 2>>"$ERROR_LOG" || echo '[]' > "$TMP_DIR/vpn_gateways.json"
    aws ec2 describe-customer-gateways --region "$REGION" --output json > "$TMP_DIR/customer_gateways.json" 2>>"$ERROR_LOG" || echo '[]' > "$TMP_DIR/customer_gateways.json"
    aws ec2 describe-transit-gateways --region "$REGION" --output json > "$TMP_DIR/transit_gateways.json" 2>>"$ERROR_LOG" || echo '[]' > "$TMP_DIR/transit_gateways.json"
    aws ec2 describe-vpc-endpoints --region "$REGION" --output json > "$TMP_DIR/vpc_endpoints.json" 2>>"$ERROR_LOG" || echo '[]' > "$TMP_DIR/vpc_endpoints.json"
    aws ec2 describe-vpc-peering-connections --region "$REGION" --output json > "$TMP_DIR/vpc_peering.json" 2>>"$ERROR_LOG" || echo '[]' > "$TMP_DIR/vpc_peering.json"

    jq -n \
        --slurpfile vpcs "$TMP_DIR/vpcs.json" \
        --slurpfile subnets "$TMP_DIR/subnets.json" \
        --slurpfile route_tables "$TMP_DIR/route_tables.json" \
        --slurpfile network_acls "$TMP_DIR/network_acls.json" \
        --slurpfile security_groups "$TMP_DIR/security_groups.json" \
        --slurpfile network_interfaces "$TMP_DIR/network_interfaces.json" \
        --slurpfile internet_gateways "$TMP_DIR/internet_gateways.json" \
        --slurpfile nat_gateways "$TMP_DIR/nat_gateways.json" \
        --slurpfile vpn_connections "$TMP_DIR/vpn_connections.json" \
        --slurpfile vpn_gateways "$TMP_DIR/vpn_gateways.json" \
        --slurpfile customer_gateways "$TMP_DIR/customer_gateways.json" \
        --slurpfile transit_gateways "$TMP_DIR/transit_gateways.json" \
        --slurpfile vpc_endpoints "$TMP_DIR/vpc_endpoints.json" \
        --slurpfile vpc_peering "$TMP_DIR/vpc_peering.json" \
        '{
            vpcs: $vpcs[0].Vpcs,
            subnets: $subnets[0].Subnets,
            route_tables: $route_tables[0].RouteTables,
            network_acls: $network_acls[0].NetworkAcls,
            security_groups: $security_groups[0].SecurityGroups,
            network_interfaces: $network_interfaces[0].NetworkInterfaces,
            internet_gateways: $internet_gateways[0].InternetGateways,
            nat_gateways: $nat_gateways[0].NatGateways,
            vpn_connections: $vpn_connections[0].VpnConnections,
            vpn_gateways: $vpn_gateways[0].VpnGateways,
            customer_gateways: $customer_gateways[0].CustomerGateways,
            transit_gateways: $transit_gateways[0].TransitGateways,
            vpc_endpoints: $vpc_endpoints[0].VpcEndpoints,
            vpc_peering_connections: $vpc_peering[0].VpcPeeringConnections
        }' > "$TMP_DIR/region.json"

    jq --arg region "$REGION" --slurpfile data "$TMP_DIR/region.json" \
        '. + {($region): $data[0]}' "$OUTPUT_JSON" > "$TMP_DIR/tmp.json" && mv "$TMP_DIR/tmp.json" "$OUTPUT_JSON"

    echo "- VPCs: $(jq '.Vpcs | length' "$TMP_DIR/vpcs.json")" >> "$OUTPUT_MD"
    echo "- Subnets: $(jq '.Subnets | length' "$TMP_DIR/subnets.json")" >> "$OUTPUT_MD"
    echo "- Route Tables: $(jq '.RouteTables | length' "$TMP_DIR/route_tables.json")" >> "$OUTPUT_MD"
    echo "- Security Groups: $(jq '.SecurityGroups | length' "$TMP_DIR/security_groups.json")" >> "$OUTPUT_MD"
    echo "- Internet Gateways: $(jq '.InternetGateways | length' "$TMP_DIR/internet_gateways.json")" >> "$OUTPUT_MD"
    echo "- NAT Gateways: $(jq '.NatGateways | length' "$TMP_DIR/nat_gateways.json")" >> "$OUTPUT_MD"
    echo "- VPN Connections: $(jq '.VpnConnections | length' "$TMP_DIR/vpn_connections.json")" >> "$OUTPUT_MD"
    echo "- VPN Gateways: $(jq '.VpnGateways | length' "$TMP_DIR/vpn_gateways.json")" >> "$OUTPUT_MD"
    echo "- Transit Gateways: $(jq '.TransitGateways | length' "$TMP_DIR/transit_gateways.json")" >> "$OUTPUT_MD"
    echo "- VPC Endpoints: $(jq '.VpcEndpoints | length' "$TMP_DIR/vpc_endpoints.json")" >> "$OUTPUT_MD"
    echo "- VPC Peering Connections: $(jq '.VpcPeeringConnections | length' "$TMP_DIR/vpc_peering.json")" >> "$OUTPUT_MD"
    echo "" >> "$OUTPUT_MD"

    rm -f $TMP_DIR/*.json

done

gzip -f "$OUTPUT_JSON"
rm -rf "$TMP_DIR"
echo "✓ Informacion almacenada en ${OUTPUT_JSON}.gz y resumen en $OUTPUT_MD"
echo "✓ Errores (si hubo) registrados en $ERROR_LOG"
