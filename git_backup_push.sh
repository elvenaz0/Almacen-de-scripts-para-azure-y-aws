#!/bin/bash

# Script de respaldo automático con Git

REPO_URL="https://github.com/elvenaz0/Almacen-de-scripts-para-azure-y-aws.git"
BRANCH="main"
MENSAJE="backup con la fecha actual: 2025-04-15 18:56:12"

# Asegurarse de estar en el repositorio
if [ ! -d .git ]; then
  echo "❌ Este directorio no es un repositorio de Git. Clonando..."
  git clone $REPO_URL repo_temp
  cd repo_temp || exit 1
fi

# Agregar cambios, hacer commit y push
echo "➕ Agregando archivos..."
git add .

echo "💬 Haciendo commit..."
git commit -m "$MENSAJE"

echo "🚀 Haciendo push a $BRANCH..."
git push origin $BRANCH

echo "✅ Backup completado con éxito."
