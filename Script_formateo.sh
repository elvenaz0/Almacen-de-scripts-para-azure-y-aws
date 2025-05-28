#!/bin/bash

# Script de formateo y montaje de particiones para SAP HANA

set -e

# Crear puntos de montaje
mkdir -p /hana/data
mkdir -p /hana/shared
mkdir -p /hana/log
mkdir -p /usr/sap

# Formatear las particiones (solo si quieres forzar, sino comentar estas lineas)
 mkfs.xfs -f -L "/hana/data" /dev/nvme3n1p1
 mkfs.xfs -f -L "/hana/shared" /dev/nvme4n1p1
 mkfs.xfs -f -L "/hana/log" /dev/nvme2n1p1
 mkfs.xfs -f -L "/usr/sap" /dev/nvme1n1p1

# Realizar copia de seguridad del fstab
cp /etc/fstab /etc/fstab.bak

# Agregar entradas al /etc/fstab
cat <<EOL >> /etc/fstab
UUID=296d726d-0a39-4cca-b259-3755f264ddbf /hana/data    xfs defaults,nofail  0 0
UUID=072d8670-6a1a-4d00-a459-5d3703b190ad /hana/shared  xfs defaults,nofail  0 0
UUID=729144da-056c-4af3-a861-252c0b59d28d /hana/log     xfs defaults,nofail  0 0
UUID=f6795957-7528-4f00-9940-5124d3162873 /usr/sap      xfs defaults,nofail  0 0
EOL

# Montar las particiones
mount -a

# Verificar montaje
if df -h | grep -q "/hana/data" && \
   df -h | grep -q "/hana/shared" && \
   df -h | grep -q "/hana/log" && \
   df -h | grep -q "/usr/sap"; then
    estado_montaje="completado"
    verificado=true
else
    estado_montaje="fallido"
    verificado=false
fi

# Generar archivo JSON de resultado
cat <<EOF > resultado_formateo.json
{
  "particiones": [
    {
      "punto_montaje": "/hana/data",
      "uuid": "296d726d-0a39-4cca-b259-3755f264ddbf",
      "tipo": "xfs"
    },
    {
      "punto_montaje": "/hana/shared",
      "uuid": "072d8670-6a1a-4d00-a459-5d3703b190ad",
      "tipo": "xfs"
    },
    {
      "punto_montaje": "/hana/log",
      "uuid": "729144da-056c-4af3-a861-252c0b59d28d",
      "tipo": "xfs"
    },
    {
      "punto_montaje": "/usr/sap",
      "uuid": "f6795957-7528-4f00-9940-5124d3162873",
      "tipo": "xfs"
    }
  ],
  "estado_montaje": "${estado_montaje}",
  "verificado": ${verificado}
}
EOF

# Mensaje final
echo "\nFormateo, montaje y generación de resultado_formateo.json completado."
