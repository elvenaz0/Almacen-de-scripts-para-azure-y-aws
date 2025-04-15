
#!/bin/bash

# Parámetros
SUBSCRIPTION_ID="67ef1b15-edd4-4120-ae6e-e0e71e608182"
RESOURCE_GROUP="worldvision-application-rg"
VM_NAME="WORLDVISION-AplicativoWeb-prodeus2-vm01"

# Establecer suscripción
az account set --subscription "$SUBSCRIPTION_ID"

# Ejecutar comando remoto para ver reglas de firewall en Windows
echo "🛡️ Verificando reglas del firewall dentro de la VM..."
az vm run-command invoke \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --command-id RunPowerShellScript \
  --scripts "Get-NetFirewallRule | Where-Object { $_.Direction -eq 'Inbound' -and $_.Action -eq 'Allow' } | Select DisplayName, Enabled, Direction, Action, Profile" \
  -o table
