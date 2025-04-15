
#!/bin/bash

# Parámetros
SUBSCRIPTION_ID="67ef1b15-edd4-4120-ae6e-e0e71e608182"
RESOURCE_GROUP="WORLDVISION-Application-rg"
NIC_NAME="worldvision-aplicati632"
NSG_OUTPUT="nsg_rules_worldvision.json"

# Establecer suscripción
az account set --subscription "$SUBSCRIPTION_ID"

# Obtener el NSG asociado al NIC
NSG_ID=$(az network nic show --resource-group "$RESOURCE_GROUP" --name "$NIC_NAME" --query "networkSecurityGroup.id" -o tsv)

if [ -z "$NSG_ID" ]; then
    echo "❌ No se encontró NSG asociado al NIC: $NIC_NAME"
    exit 1
fi

# Obtener nombre del NSG a partir del ID
NSG_NAME=$(basename "$NSG_ID")

# Listar reglas del NSG y guardarlas en JSON
echo "📦 Obteniendo reglas del NSG: $NSG_NAME"
az network nsg rule list   --resource-group "$RESOURCE_GROUP"   --nsg-name "$NSG_NAME"   -o json > "$NSG_OUTPUT"

echo "✅ Reglas del NSG exportadas en: $NSG_OUTPUT"

# Validar reglas explícitas para puertos 80 y 443
echo -e "\n🔍 Reglas que permiten tráfico en puertos 80 y 443:"
az network nsg rule list   --resource-group "$RESOURCE_GROUP"   --nsg-name "$NSG_NAME"   --query "[?contains(destinationPortRange, '80') || contains(destinationPortRange, '443')]"   -o table
