# Almacen-de-scripts-para-azure-y-aws
aqui se guardan scripts tipo sh para servicios de aws y azure desde cli

## Scripts disponibles
- `ec2-info.sh`: explora todas las regiones de AWS y guarda la informacion de EC2 en `ec2-info.json`.
- `eventbridge-info.sh`: obtiene las reglas de EventBridge en todas las regiones y las guarda en `eventbridge-rules.json`.
- `network-audit.sh`: recopila informacion de redes (VPC, VPN, tablas de ruteo, security groups, etc.) en todas las regiones. Genera `network-info.json.gz` con la informacion agrupada por servicio y un resumen en `network-info.md`.
- `network-audit-region.sh`: version mejorada que organiza la informacion por region e incluye detalles de endpoints, peering y otros servicios de red. Produce `network-report.json.gz` y un resumen en `network-report.md`.
- `vpn-diagnostico.sh`: diagnostica una conexion VPN de Azure buscando la suscripcion correcta y guarda la salida en JSON.

Ejemplo de uso:
```sh
./ec2-info.sh
./eventbridge-info.sh
./network-audit.sh
./network-audit-region.sh
./vpn-diagnostico.sh
```
