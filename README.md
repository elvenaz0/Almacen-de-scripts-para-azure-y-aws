# Almacen-de-scripts-para-azure-y-aws
aqui se guardan scripts tipo sh para servicios de aws y azure desde cli

## Scripts disponibles
- `ec2-info.sh`: explora todas las regiones de AWS y guarda la informacion de EC2 en `ec2-info.json`.
- `eventbridge-info.sh`: obtiene las reglas de EventBridge en todas las regiones y las guarda en `eventbridge-rules.json`.

Ejemplo de uso:
```sh
./ec2-info.sh
./eventbridge-info.sh
```
