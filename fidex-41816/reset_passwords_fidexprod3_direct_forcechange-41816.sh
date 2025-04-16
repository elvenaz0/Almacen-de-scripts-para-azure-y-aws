
#!/bin/bash

# Comando corregido para enviar instrucciones a la instancia Windows directamente
aws ssm send-command \
  --document-name "AWS-RunPowerShellScript" \
  --instance-ids i-0e4d1937f5bb18510 \
  --comment "Resetear contraseñas usuarios Windows y forzar cambio en próximo login" \
  --parameters commands='
    # Cambiar contraseñas de usuarios y forzar cambio en el próximo inicio de sesión
    net user fidex-adm C0ntr4Adm2025! /logonpasswordchg:yes;
    net user Administrator Adm1n!2025# /logonpasswordchg:yes;' \
  --timeout-seconds 60 \
  --region us-west-2 \
  --output json
