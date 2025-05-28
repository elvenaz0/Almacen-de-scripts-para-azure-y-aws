
#!/bin/bash

OUTPUT="reporte_redes_aws.json"
REGION_LIST=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)

echo "{" > $OUTPUT
first_region=true

for REGION in $REGION_LIST; do
  VPCS=$(aws ec2 describe-vpcs --region "$REGION" --output json)
  SUBNETS=$(aws ec2 describe-subnets --region "$REGION" --output json)
  ROUTES=$(aws ec2 describe-route-tables --region "$REGION" --output json)
  NACL=$(aws ec2 describe-network-acls --region "$REGION" --output json)
  SG=$(aws ec2 describe-security-groups --region "$REGION" --output json)
  ENI=$(aws ec2 describe-network-interfaces --region "$REGION" --output json)
  IGW=$(aws ec2 describe-internet-gateways --region "$REGION" --output json)
  VGW=$(aws ec2 describe-vpn-gateways --region "$REGION" --output json)
  TGW=$(aws ec2 describe-transit-gateways --region "$REGION" --output json)
  VPCE=$(aws ec2 describe-vpc-endpoints --region "$REGION" --output json)
  VPC_PEERING=$(aws ec2 describe-vpc-peering-connections --region "$REGION" --output json)

  $first_region || echo "," >> $OUTPUT
  first_region=false

  echo "  \"$REGION\": {" >> $OUTPUT
  echo "    \"VPCs\": $VPCS," >> $OUTPUT
  echo "    \"Subnets\": $SUBNETS," >> $OUTPUT
  echo "    \"RouteTables\": $ROUTES," >> $OUTPUT
  echo "    \"NetworkACLs\": $NACL," >> $OUTPUT
  echo "    \"SecurityGroups\": $SG," >> $OUTPUT
  echo "    \"NetworkInterfaces\": $ENI," >> $OUTPUT
  echo "    \"InternetGateways\": $IGW," >> $OUTPUT
  echo "    \"VPNGateways\": $VGW," >> $OUTPUT
  echo "    \"TransitGateways\": $TGW," >> $OUTPUT
  echo "    \"VPCEndpoints\": $VPCE," >> $OUTPUT
  echo "    \"VPCPeeringConnections\": $VPC_PEERING" >> $OUTPUT
  echo -n "  }" >> $OUTPUT
done

echo "" >> $OUTPUT
echo "}" >> $OUTPUT

echo "✅ Reporte generado: $OUTPUT"
