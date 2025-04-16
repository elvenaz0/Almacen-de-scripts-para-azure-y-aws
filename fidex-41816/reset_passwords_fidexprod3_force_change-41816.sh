
#!/bin/bash

# Cambiar contraseñas de usuarios en la instancia i-0e4d1937f5bb18510 y forzar cambio en login
aws ssm send-command \
  --document-name "AWS-RunPowerShellScript" \
  --targets "Key=instanceIds,Values=i-0e4d1937f5bb18510" \
  --comment "Resetear contraseñas usuarios Windows y forzar cambio en próximo login" \
  --parameters commands='
    
    net user fidex-adm C0ntr4Adm2025! /logonpasswordchg:yes;
    net user Administrator Adm1n!2025# /logonpasswordchg:yes;' \
  --timeout-seconds 60 \
  --region us-west-2 \
  --output json
