#!/bin/bash
# Script para generar un reporte completo del servicio IAM de AWS usando la AWS CLI

# Crear un directorio para almacenar el reporte con marca de fecha y hora
REPORT_DIR="./aws-iam-report-$(date +'%Y%m%d-%H%M%S')"
mkdir -p "${REPORT_DIR}"

echo "Generando reporte IAM en AWS en el directorio ${REPORT_DIR}..."

##############################
# 1. Reporte de Usuarios IAM
##############################
echo "Obteniendo lista de usuarios..."
aws iam list-users > "${REPORT_DIR}/iam-users.json"

# Por cada usuario, se recolecta información adicional
USER_LIST=$(aws iam list-users --query 'Users[].UserName' --output text)
for user in $USER_LIST; do
  echo "Procesando usuario: $user"
  aws iam list-attached-user-policies --user-name "$user" > "${REPORT_DIR}/iam-user-attached-policies-${user}.json"
  aws iam list-user-policies --user-name "$user" > "${REPORT_DIR}/iam-user-inline-policies-${user}.json"
  aws iam list-mfa-devices --user-name "$user" > "${REPORT_DIR}/iam-user-mfa-devices-${user}.json"
  aws iam list-access-keys --user-name "$user" > "${REPORT_DIR}/iam-user-access-keys-${user}.json"
done

##############################
# 2. Reporte de Grupos IAM
##############################
echo "Obteniendo lista de grupos..."
aws iam list-groups > "${REPORT_DIR}/iam-groups.json"

GROUP_LIST=$(aws iam list-groups --query 'Groups[].GroupName' --output text)
for group in $GROUP_LIST; do
  echo "Procesando grupo: $group"
  aws iam list-attached-group-policies --group-name "$group" > "${REPORT_DIR}/iam-group-attached-policies-${group}.json"
  aws iam list-group-policies --group-name "$group" > "${REPORT_DIR}/iam-group-inline-policies-${group}.json"
done

##############################
# 3. Reporte de Roles IAM
##############################
echo "Obteniendo lista de roles..."
aws iam list-roles > "${REPORT_DIR}/iam-roles.json"

ROLE_LIST=$(aws iam list-roles --query 'Roles[].RoleName' --output text)
for role in $ROLE_LIST; do
  echo "Procesando rol: $role"
  aws iam list-attached-role-policies --role-name "$role" > "${REPORT_DIR}/iam-role-attached-policies-${role}.json"
  aws iam list-role-policies --role-name "$role" > "${REPORT_DIR}/iam-role-inline-policies-${role}.json"
done

##############################
# 4. Reporte de Políticas IAM
##############################
echo "Obteniendo lista de políticas (todas)..."
aws iam list-policies --scope All > "${REPORT_DIR}/iam-policies.json"

##############################
# 5. Reporte de Proveedores de Identidad
##############################
echo "Obteniendo lista de proveedores SAML..."
aws iam list-saml-providers > "${REPORT_DIR}/iam-saml-providers.json"

echo "Obteniendo lista de proveedores OpenID Connect..."
aws iam list-open-id-connect-providers > "${REPORT_DIR}/iam-oidc-providers.json"

echo "Reporte completado. Los archivos se encuentran en: ${REPORT_DIR}"
