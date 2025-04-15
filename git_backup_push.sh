#!/bin/bash
# Script de respaldo automático con Git

echo "⚙️  Iniciando proceso de backup automático..."

# Configuración del repositorio y branch
REPO_URL="https://github.com/elvenaz0/Almacen-de-scripts-para-azure-y-aws.git"
BRANCH="main"

# Generar la fecha y hora actual de forma dinámica
FECHA=$(date '+%Y-%m-%d %H:%M:%S')
MENSAJE="Backup automático - $FECHA"

# Verificar si el directorio actual es un repositorio Git
if [ ! -d ".git" ]; then
  echo "❌ Este directorio no es un repositorio de Git. Clonando repositorio..."
  git clone "$REPO_URL" repo_temp
  if [ $? -ne 0 ]; then
    echo "⚠️ Error: La clonación del repositorio falló."
    exit 1
  fi
  cd repo_temp || { echo "⚠️ Error: No se pudo acceder al directorio clonado."; exit 1; }
fi

# Mostrar el estado actual del repositorio
echo "🔍 Estado del repositorio:"
git status

# Agregar archivos modificados y nuevos
echo "➕ Agregando archivos al área de staging..."
git add .

# Realizar commit con el mensaje dinámico
echo "💬 Realizando commit con el mensaje: \"$MENSAJE\""
git commit -m "$MENSAJE"
if [ $? -ne 0 ]; then
  echo "⚠️ Advertencia: No se realizaron cambios o el commit falló."
fi

# Enviar los cambios al repositorio remoto
echo "🚀 Realizando push al branch \"$BRANCH\"..."
git push origin "$BRANCH"
if [ $? -ne 0 ]; then
  echo "⚠️ Error: El push falló."
  exit 1
fi

echo "✅ Backup completado con éxito."
