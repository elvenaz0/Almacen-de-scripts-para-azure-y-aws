#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# create-ha-ecommerce.sh
# Script DEMO: despliega una arquitectura de e-commerce altamente disponible
# empleando AWS CLI v2. Pensado para ejecutarse en AWS CloudShell (cuenta limpia
# con permisos de administrador). Los parametros se pueden definir en un archivo
# .env o como variables de entorno.
# ---------------------------------------------------------------------------
set -euo pipefail

# -----------------------------
# Utilidades
# -----------------------------
log() { printf '\e[1;34m[+] %s\e[0m\n' "$1"; }
err() { printf '\e[1;31m[!] %s\e[0m\n' "$1"; }
json_id() { jq -r "$1"; }

# -----------------------------
# Carga parametros
# -----------------------------
[ -f .env ] && source .env

PROJECT_NAME=${PROJECT_NAME:-"demo-store"}
REGION=${REGION:-"us-east-1"}

VPC_CIDR=${VPC_CIDR:-"10.0.0.0/16"}
PUB_A_CIDR=${PUB_A_CIDR:-"10.0.0.0/24"}
PUB_B_CIDR=${PUB_B_CIDR:-"10.0.1.0/24"}
PRI_A_CIDR=${PRI_A_CIDR:-"10.0.10.0/24"}
PRI_B_CIDR=${PRI_B_CIDR:-"10.0.11.0/24"}
DB_A_CIDR=${DB_A_CIDR:-"10.0.20.0/28"}
DB_B_CIDR=${DB_B_CIDR:-"10.0.21.0/28"}

DOMAIN_NAME=${DOMAIN_NAME:-"example.com."}
ADMIN_EMAIL=${ADMIN_EMAIL:-"admin@${DOMAIN_NAME%.}"}

AMI_ID=${AMI_ID:-""}
INSTANCE_TYPE=${INSTANCE_TYPE:-"t3.medium"}
KEY_PAIR_NAME=${KEY_PAIR_NAME:-"${PROJECT_NAME}-key"}
DB_ENGINE=${DB_ENGINE:-"mysql"}
DB_ENGINE_VERSION=${DB_ENGINE_VERSION:-"8.0.35"}
DB_INSTANCE_CLASS=${DB_INSTANCE_CLASS:-"db.t3.medium"}
DB_USERNAME=${DB_USERNAME:-"admin"}
DB_PASSWORD=${DB_PASSWORD:-"$(openssl rand -base64 16)"}

aws configure set region "$REGION" >/dev/null
export AWS_REGION="$REGION"
export AWS_DEFAULT_REGION="$REGION"

# Array para registrar recursos creados
CREATED=()
cleanup() {
    local status=$?
    if [ $status -ne 0 ]; then
        err "Se produjo un error. Revisa y elimina los recursos listados si es necesario:"
        printf '%s\n' "${CREATED[@]}"
    fi
}
trap cleanup EXIT

# -----------------------------
# Funciones de creacion
# -----------------------------
create_vpc() {
    log "Creando VPC ($VPC_CIDR)…"
    VPC_ID=$(aws ec2 create-vpc --cidr-block "$VPC_CIDR" \
      --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT_NAME}-vpc}]" | json_id '.Vpc.VpcId')
    aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-hostnames
    aws ec2 modify-vpc-attribute --vpc-id "$VPC_ID" --enable-dns-support
    CREATED+=("aws ec2 delete-vpc --vpc-id $VPC_ID")
    log "VPC_ID=$VPC_ID"
}

create_subnets() {
    log "Creando subredes…"
    create_subnet() {
        local cidr=$1 az=$2 name=$3
        aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "$cidr" --availability-zone "$az" \
          --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$name}]" | json_id '.Subnet.SubnetId'
    }
    PUB_A_ID=$(create_subnet "$PUB_A_CIDR" "${REGION}a" "${PROJECT_NAME}-pub-a")
    PUB_B_ID=$(create_subnet "$PUB_B_CIDR" "${REGION}b" "${PROJECT_NAME}-pub-b")
    PRI_A_ID=$(create_subnet "$PRI_A_CIDR" "${REGION}a" "${PROJECT_NAME}-pri-a")
    PRI_B_ID=$(create_subnet "$PRI_B_CIDR" "${REGION}b" "${PROJECT_NAME}-pri-b")
    DB_A_ID=$(create_subnet "$DB_A_CIDR" "${REGION}a" "${PROJECT_NAME}-db-a")
    DB_B_ID=$(create_subnet "$DB_B_CIDR" "${REGION}b" "${PROJECT_NAME}-db-b")
    log "Subredes creadas: $PUB_A_ID $PUB_B_ID $PRI_A_ID $PRI_B_ID $DB_A_ID $DB_B_ID"
}

create_routing() {
    log "Creando IGW y tablas de ruteo…"
    IGW_ID=$(aws ec2 create-internet-gateway --tag-specifications \
      "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${PROJECT_NAME}-igw}]" | json_id '.InternetGateway.InternetGatewayId')
    aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID"
    CREATED+=("aws ec2 detach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID" "aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID")

    RT_PUBLIC=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications \
      "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_NAME}-rt-public}]" | json_id '.RouteTable.RouteTableId')
    aws ec2 create-route --route-table-id "$RT_PUBLIC" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" >/dev/null
    for SUB in $PUB_A_ID $PUB_B_ID; do aws ec2 associate-route-table --subnet-id "$SUB" --route-table-id "$RT_PUBLIC"; done

    RT_PRIVATE=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --tag-specifications \
      "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT_NAME}-rt-private}]" | json_id '.RouteTable.RouteTableId')
    for SUB in $PRI_A_ID $PRI_B_ID $DB_A_ID $DB_B_ID; do aws ec2 associate-route-table --subnet-id "$SUB" --route-table-id "$RT_PRIVATE"; done
    log "IGW_ID=$IGW_ID, RT_PUBLIC=$RT_PUBLIC, RT_PRIVATE=$RT_PRIVATE"
}

create_nacls() {
    log "Aplicando NACLs…"
    create_nacl() {
        local name=$1; local acl_id
        acl_id=$(aws ec2 create-network-acl --vpc-id "$VPC_ID" --tag-specifications \
          "ResourceType=network-acl,Tags=[{Key=Name,Value=$name}]" | json_id '.NetworkAcl.NetworkAclId')
        aws ec2 create-network-acl-entry --network-acl-id "$acl_id" --egress --rule-number 100 --protocol -1 \
          --port-range From=0,To=0 --cidr 0.0.0.0/0 --rule-action allow
        echo "$acl_id"
    }
    NACL_PUB=$(create_nacl "${PROJECT_NAME}-nacl-public")
    NACL_PRI=$(create_nacl "${PROJECT_NAME}-nacl-private")
    for SUB in $PUB_A_ID $PUB_B_ID; do aws ec2 associate-network-acl --subnet-id "$SUB" --network-acl-id "$NACL_PUB"; done
    for SUB in $PRI_A_ID $PRI_B_ID $DB_A_ID $DB_B_ID; do aws ec2 associate-network-acl --subnet-id "$SUB" --network-acl-id "$NACL_PRI"; done
    log "NACLs: $NACL_PUB $NACL_PRI"
}

create_hosted_zone() {
    log "Creando Hosted Zone ($DOMAIN_NAME)…"
    HZ_ID=$(aws route53 create-hosted-zone --name "$DOMAIN_NAME" --caller-reference "$(date +%s)-${PROJECT_NAME}" \
      --hosted-zone-config Comment="Hosted zone for ${PROJECT_NAME}",PrivateZone=false | json_id '.HostedZone.Id' | cut -d'/' -f3)
    log "Hosted Zone creada: $HZ_ID"
}

create_security_groups() {
    log "Creando Security Groups…"
    ALB_SG=$(aws ec2 create-security-group --group-name "${PROJECT_NAME}-alb-sg" --description "ALB SG" --vpc-id "$VPC_ID" | json_id '.GroupId')
    EC2_SG=$(aws ec2 create-security-group --group-name "${PROJECT_NAME}-ec2-sg" --description "EC2 SG" --vpc-id "$VPC_ID" | json_id '.GroupId')
    RDS_SG=$(aws ec2 create-security-group --group-name "${PROJECT_NAME}-rds-sg" --description "RDS SG" --vpc-id "$VPC_ID" | json_id '.GroupId')
    aws ec2 authorize-security-group-ingress --group-id "$ALB_SG" --protocol tcp --port 80 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id "$ALB_SG" --protocol tcp --port 443 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id "$EC2_SG" --protocol tcp --port 80 --source-group "$ALB_SG"
    aws ec2 authorize-security-group-ingress --group-id "$EC2_SG" --protocol tcp --port 443 --source-group "$ALB_SG"
    aws ec2 authorize-security-group-ingress --group-id "$RDS_SG" --protocol tcp --port 3306 --source-group "$EC2_SG"
    log "SGs: ALB=$ALB_SG EC2=$EC2_SG RDS=$RDS_SG"
}

prepare_ami_and_key() {
    if ! aws ec2 describe-key-pairs --key-names "$KEY_PAIR_NAME" >/dev/null 2>&1; then
        log "Creando key pair $KEY_PAIR_NAME (guardado en ~/.ssh)…"
        aws ec2 create-key-pair --key-name "$KEY_PAIR_NAME" --query 'KeyMaterial' --output text > "$HOME/.ssh/${KEY_PAIR_NAME}.pem"
        chmod 400 "$HOME/.ssh/${KEY_PAIR_NAME}.pem"
    fi
    if [[ -z "$AMI_ID" ]]; then
        log "Buscando ultima Amazon Linux 2023 AMI…"
        AMI_ID=$(aws ec2 describe-images --owners amazon --filters 'Name=name,Values=al2023-ami-*-x86_64*' 'Name=state,Values=available' \
          | jq -r '.Images | sort_by(.CreationDate) | last(.[]).ImageId')
    fi
    log "Usaremos AMI $AMI_ID"
}

create_asg_and_alb() {
    log "Creando Launch Template y Auto Scaling Group…"
    LT_ID=$(aws ec2 create-launch-template --launch-template-name "${PROJECT_NAME}-lt" --version-description "v1" \
      --launch-template-data "{\"ImageId\":\"$AMI_ID\",\"InstanceType\":\"$INSTANCE_TYPE\",\"KeyName\":\"$KEY_PAIR_NAME\",\"SecurityGroupIds\":[\"$EC2_SG\"],\"UserData\":\"$(echo -n '#!/bin/bash\nyum -y install httpd\nsystemctl enable --now httpd\necho "OK" > /var/www/html/health' | base64 -w0)\"}" | json_id '.LaunchTemplate.LaunchTemplateId')
    TG_ARN=$(aws elbv2 create-target-group --name "${PROJECT_NAME}-tg" --protocol HTTP --port 80 --target-type instance --vpc-id "$VPC_ID" | json_id '.TargetGroups[0].TargetGroupArn')
    ALB_ARN=$(aws elbv2 create-load-balancer --name "${PROJECT_NAME}-alb" --subnets "$PUB_A_ID" "$PUB_B_ID" --security-groups "$ALB_SG" --scheme internet-facing --type application | json_id '.LoadBalancers[0].LoadBalancerArn')
    ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ALB_ARN" | json_id '.LoadBalancers[0].DNSName')
    aws elbv2 create-listener --load-balancer-arn "$ALB_ARN" --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn="$TG_ARN" >/dev/null
    aws autoscaling create-auto-scaling-group --auto-scaling-group-name "${PROJECT_NAME}-asg" --launch-template "LaunchTemplateId=$LT_ID,Version=1" --min-size 2 --desired-capacity 2 --max-size 6 --vpc-zone-identifier "$PRI_A_ID,$PRI_B_ID" --target-group-arns "$TG_ARN"
    aws autoscaling put-scaling-policy --auto-scaling-group-name "${PROJECT_NAME}-asg" --policy-name "cpu60" --policy-type TargetTrackingScaling --target-tracking-configuration '{"PredefinedMetricSpecification":{"PredefinedMetricType":"ASGAverageCPUUtilization"},"TargetValue":60}'
    log "ALB DNS: $ALB_DNS"
}

create_rds() {
    log "Creando subnet group para RDS…"
    RDS_SUBNET_GROUP=$(aws rds create-db-subnet-group --db-subnet-group-name "${PROJECT_NAME}-dbsg" --db-subnet-group-description "${PROJECT_NAME} db subnets" --subnet-ids "$DB_A_ID" "$DB_B_ID" | json_id '.DBSubnetGroup.DBSubnetGroupName')
    log "Creando RDS Multi-AZ…"
    aws rds create-db-instance --db-instance-identifier "${PROJECT_NAME}-rds" --engine "$DB_ENGINE" --engine-version "$DB_ENGINE_VERSION" --db-instance-class "$DB_INSTANCE_CLASS" --multi-az --allocated-storage 20 --master-username "$DB_USERNAME" --master-user-password "$DB_PASSWORD" --vpc-security-group-ids "$RDS_SG" --db-subnet-group-name "$RDS_SUBNET_GROUP" --backup-retention-period 7 --storage-type gp3 --publicly-accessible false
}

create_s3_and_cf() {
    BUCKET_NAME="${PROJECT_NAME}-static-$(date +%s)"
    log "Creando bucket S3 $BUCKET_NAME…"
    aws s3api create-bucket --bucket "$BUCKET_NAME" --create-bucket-configuration LocationConstraint="$REGION"
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
    aws s3api put-bucket-encryption --bucket "$BUCKET_NAME" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
    log "Creando Origin Access Control…"
    OAC_ID=$(aws cloudfront create-origin-access-control --origin-access-control-config '{"Name":"'${PROJECT_NAME// /}-oac'","SigningBehavior":"always","SigningProtocol":"sigv4","OriginAccessControlOriginType":"s3"}' | json_id '.OriginAccessControl.Id')
    log "Creando distribucion CloudFront…"
    CF_DIST_ID=$(aws cloudfront create-distribution --distribution-config '{
      "CallerReference":"'$(date +%s)'","Comment":"'${PROJECT_NAME}'","Enabled":true,
      "Origins":{"Items":[{"Id":"s3-origin","DomainName":"'$BUCKET_NAME'.s3.'$REGION'.amazonaws.com","S3OriginConfig":{"OriginAccessIdentity":""},"OriginAccessControlId":"'$OAC_ID'"}],"Quantity":1},
      "DefaultCacheBehavior":{"TargetOriginId":"s3-origin","ViewerProtocolPolicy":"redirect-to-https","AllowedMethods":{"Quantity":2,"Items":["GET","HEAD"]},"CachedMethods":{"Quantity":2,"Items":["GET","HEAD"]},"Compress":true,"DefaultTTL":3600},
      "DefaultRootObject":"index.html"}' | json_id '.Distribution.Id')
}

create_dns_record() {
    log "Creando registro A para el dominio…"
    aws route53 change-resource-record-sets --hosted-zone-id "$HZ_ID" --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"'${DOMAIN_NAME}'","Type":"A","AliasTarget":{"HostedZoneId":"Z35SXDOTRQ7X7K","DNSName":"'${ALB_DNS}'","EvaluateTargetHealth":true}}}]}' >/dev/null
}

summary() {
    cat <<EOF2

Script completado. Recursos principales:
---------------------------------------
VPC_ID          = $VPC_ID
ALB_DNS         = $ALB_DNS
RDS_ID          = ${PROJECT_NAME}-rds
S3_BUCKET       = $BUCKET_NAME
CF_DISTRIBUTION = $CF_DIST_ID
HOSTED_ZONE_ID  = $HZ_ID
EOF2
}

# -----------------------------
# Ejecucion
# -----------------------------
log "Trabajando en region $REGION con proyecto $PROJECT_NAME"
create_vpc
create_subnets
create_routing
create_nacls
create_hosted_zone
create_security_groups
prepare_ami_and_key
create_asg_and_alb
create_rds
create_s3_and_cf
create_dns_record
summary

