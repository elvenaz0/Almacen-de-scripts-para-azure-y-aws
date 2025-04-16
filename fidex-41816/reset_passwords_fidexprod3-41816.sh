
#!/bin/bash

# Cambiar contraseñas de usuarios en la instancia i-0e4d1937f5bb18510
aws ssm send-command \
  --document-name "AWS-RunPowerShellScript" \
  --targets "Key=instanceIds,Values=i-0e4d1937f5bb18510" \
  --comment "Resetear contraseñas usuarios Windows" \
  --parameters commands='
    net user fidexadm S3gura2025!;
    net user fidex-adm C0ntr4Adm2025!;
    net user Administrator Adm1n!2025#;' \
  --timeout-seconds 60 \
  --region us-west-2 \
  --output json
