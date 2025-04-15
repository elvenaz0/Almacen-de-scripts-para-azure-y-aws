
#!/bin/bash

# Parámetros
SUBSCRIPTION_ID="67ef1b15-edd4-4120-ae6e-e0e71e608182"
RESOURCE_GROUP="worldvision-application-rg"
VM_NAME="WORLDVISION-AplicativoWeb-prodeus2-vm01"
OUTPUT_FILE="vm_estado_worldvision.json"

# Seleccionar suscripción
az account set --subscription "$SUBSCRIPTION_ID"

# Verificar estado actual de la VM
echo "📌 Estado de encendido de la VM:"
az vm get-instance-view \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" \
  -o table

# Obtener toda la información de la VM y guardarla en un archivo JSON
echo "📦 Exportando información completa de la VM a: $OUTPUT_FILE"
az vm show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --show-details \
  -o json > "$OUTPUT_FILE"

echo "✅ Información exportada correctamente."
