#!/bin/bash

set -e

# --- Configuración ---
DISTRIBUTIONS=("E23LJODJMYQ4NS" "E37XDHJWHQZM9I")
NEW_CNAME1="eleccionjudicial2025.ieem.org.mx"
NEW_CNAME2="judicial2025.ieem.org.mx"
CERT_ARN="arn:aws:acm:us-east-1:244055118102:certificate/abf3d72b-8320-45be-b61d-34c5bdf90d36"

# --- Loop para cada distribución ---
for DIST_ID in "${DISTRIBUTIONS[@]}"; do
  echo "📥 Obteniendo configuración de la distribución $DIST_ID..."
  aws cloudfront get-distribution-config \
    --id "$DIST_ID" > "${DIST_ID}_raw.json"

  E_TAG=$(jq -r '.ETag' "${DIST_ID}_raw.json")
  jq '.DistributionConfig' "${DIST_ID}_raw.json" > "${DIST_ID}_config.json"

  echo "✏️ Modificando CNAMEs y certificado SSL..."
  jq --arg cname1 "$NEW_CNAME1" \
     --arg cname2 "$NEW_CNAME2" \
     --arg cert "$CERT_ARN" '
    .Aliases.Items = [$cname1, $cname2] |
    .Aliases.Quantity = 2 |
    .ViewerCertificate = {
      ACMCertificateArn: $cert,
      SSLSupportMethod: "sni-only",
      MinimumProtocolVersion: "TLSv1.2_2021",
      Certificate: $cert,
      CertificateSource: "acm"
    }
  ' "${DIST_ID}_config.json" > "${DIST_ID}_config_updated.json"

  echo "🚀 Aplicando actualización en $DIST_ID..."
  aws cloudfront update-distribution \
    --id "$DIST_ID" \
    --if-match "$E_TAG" \
    --distribution-config file://"${DIST_ID}_config_updated.json"

  echo "✅ Distribución $DIST_ID actualizada con nuevos CNAMEs y certificado SSL."
done

# --- Generar reporte ---
echo "📝 Generando reporte..."
REPORT_FILE="cloudfront_cname_update_$(date +%Y%m%d_%H%M%S).json"
jq -n \
  --arg cname1 "$NEW_CNAME1" \
  --arg cname2 "$NEW_CNAME2" \
  --arg cert "$CERT_ARN" \
  --argjson ids "$(printf '%s\n' "${DISTRIBUTIONS[@]}" | jq -R . | jq -s .)" \
  '{updated_distributions: $ids, new_cnames: [$cname1, $cname2], certificate_used: $cert, timestamp: now | todate}' \
  > "$REPORT_FILE"

echo "📄 Reporte generado: $REPORT_FILE"
