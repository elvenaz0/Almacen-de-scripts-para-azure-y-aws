#!/bin/bash
# Lista de instancias a consultar
instancias=(
    "FidexAppsProd2"
    "FidexAppsProd3"
    "FidexAppsProd4"
    "FidexAppsProd5"
    "FidexAppsProd7"
    "FidexAppsProd9"
    "FidexSopProd3"
    "FidexSopProd4"
    "FidexDBProd1"
)

# Archivo de salida
output_file="instancias.json"
# Inicia el archivo JSON con un array
echo "[" > "$output_file"

# Contador para saber si es la última entrada (para evitar coma al final)
total=${#instancias[@]}
contador=0

# Recorre cada instancia
for instancia in "${instancias[@]}"; do
    contador=$((contador+1))
    
    # Consulta AWS filtrando por la etiqueta Name
    # Nota: Se asume que cada instancia está identificada por la etiqueta "Name"
    info=$(aws ec2 describe-instances \
      --filters "Name=tag:Name,Values=${instancia}" \
      --query "Reservations[].Instances[]" \
      --output json)

    # Extrae los campos, usando jq y la función // para asignar un valor por defecto "null" en caso de no existir.
    # Convertimos el string "null" a valor nulo en el JSON final.
    ip=$(echo "$info" | jq -r '.[0].PublicIpAddress // "null"')
    ami=$(echo "$info" | jq -r '.[0].ImageId // "null"')
    # Se extraen los discos: se toma el bloque de mappings, se puede ajustar según la salida deseada.
    discos=$(echo "$info" | jq -c '.[0].BlockDeviceMappings // null')
    # Información de red (por ejemplo, interfaces de red)
    red=$(echo "$info" | jq -c '.[0].NetworkInterfaces // null')
    # Opciones de CPU (cantidad de núcleos, etc.)
    cpu=$(echo "$info" | jq -c '.[0].CpuOptions // null')
    # Estado de optimización EBS
    ebs=$(echo "$info" | jq -r '.[0].EbsOptimized // "null"')
    # Tipo de instancia (usado para determinar la "familia")
    tipo_instancia=$(echo "$info" | jq -r '.[0].InstanceType // "null"')
    # Campo de software licenciado por CPU (en este ejemplo, se asigna siempre null)
    software_por_cpu="null"

    # Construye el objeto JSON para la instancia
    json_obj=$(jq -n \
      --arg instancia "$instancia" \
      --arg ip "$ip" \
      --arg elastic_ip "null" \
      --argjson discos "$discos" \
      --arg ami "$ami" \
      --argjson red "$red" \
      --argjson cpu "$cpu" \
      --arg ebs "$ebs" \
      --arg tipo_instancia "$tipo_instancia" \
      --arg software_por_cpu "$software_por_cpu" \
      '{
          instancia: $instancia,
          ip: ($ip | if .=="null" then null else . end),
          elastic_ip: null, 
          discos: $discos,
          ami: ($ami | if .=="null" then null else . end),
          red: $red,
          cpu: $cpu,
          ebs: ($ebs | if .=="null" then null else . end),
          tipo_de_familia: ($tipo_instancia | if .=="null" then null else . end),
          software_por_cpu: null
      }')

    # Escribe el objeto en el archivo, añadiendo coma si no es el último
    if [ $contador -lt $total ]; then
        echo "  $json_obj," >> "$output_file"
    else
        echo "  $json_obj" >> "$output_file"
    fi
done

# Cierra el array JSON
echo "]" >> "$output_file"

echo "Archivo JSON generado: $output_file"

