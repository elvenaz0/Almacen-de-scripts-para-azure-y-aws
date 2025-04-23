
#!/bin/bash

OUTPUT_FILE="recursos_activos_por_region.json"
echo "{" > $OUTPUT_FILE

REGIONES=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)
FIRST=true

for REGION in $REGIONES; do
  REGION_OUTPUT=""
  has_resources=false

  ec2=$(aws ec2 describe-instances --region "$REGION" --query "Reservations[*].Instances[*].InstanceId" --output json)
  ebs=$(aws ec2 describe-volumes --region "$REGION" --query "Volumes[*].VolumeId" --output json)
  vpcs=$(aws ec2 describe-vpcs --region "$REGION" --query "Vpcs[*].VpcId" --output json)
  rds=$(aws rds describe-db-instances --region "$REGION" --query "DBInstances[*].DBInstanceIdentifier" --output json)
  lambda=$(aws lambda list-functions --region "$REGION" --query "Functions[*].FunctionName" --output json)
  apis=$(aws apigateway get-rest-apis --region "$REGION" --query "items[*].name" --output json)
  ddb=$(aws dynamodb list-tables --region "$REGION" --query "TableNames" --output json)
  sqs=$(aws sqs list-queues --region "$REGION" --query "QueueUrls" --output json)
  sns=$(aws sns list-topics --region "$REGION" --query "Topics[*].TopicArn" --output json)

  if [ "$REGION" == "${REGIONES%% *}" ]; then
    iam=$(aws iam list-users --query "Users[*].UserName" --output json)
    s3=$(aws s3api list-buckets --query "Buckets[*].Name" --output json)
  else
    iam="[]"
    s3="[]"
  fi

  if [[ "$ec2" != "[]" || "$ebs" != "[]" || "$vpcs" != "[]" || "$rds" != "[]" || "$lambda" != "[]" || "$apis" != "[]" || "$ddb" != "[]" || "$sqs" != "[]" || "$sns" != "[]" || "$iam" != "[]" || "$s3" != "[]" ]]; then
    $FIRST || echo "," >> $OUTPUT_FILE
    FIRST=false
    echo "  \"$REGION\": {" >> $OUTPUT_FILE
    echo "    \"EC2\": $ec2," >> $OUTPUT_FILE
    echo "    \"EBS\": $ebs," >> $OUTPUT_FILE
    echo "    \"VPC\": $vpcs," >> $OUTPUT_FILE
    echo "    \"RDS\": $rds," >> $OUTPUT_FILE
    echo "    \"Lambda\": $lambda," >> $OUTPUT_FILE
    echo "    \"APIGateway\": $apis," >> $OUTPUT_FILE
    echo "    \"DynamoDB\": $ddb," >> $OUTPUT_FILE
    echo "    \"SQS\": $sqs," >> $OUTPUT_FILE
    echo "    \"SNS\": $sns," >> $OUTPUT_FILE
    echo "    \"IAM\": $iam," >> $OUTPUT_FILE
    echo "    \"S3\": $s3" >> $OUTPUT_FILE
    echo -n "  }" >> $OUTPUT_FILE
  fi
done

echo "" >> $OUTPUT_FILE
echo "}" >> $OUTPUT_FILE

echo "✅ Resultados guardados en $OUTPUT_FILE"
