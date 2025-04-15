#!/bin/bash
# Script de respaldo automático con Git
# Este script clona el repositorio en el branch especificado, realiza commit y push con respaldo automático.

set -euo pipefail
# Descomenta la siguiente línea para ver el detalle de la ejecución:
# set -x

# Verificar que Git esté instalado
if ! command -v git >/dev/null 2>&1; then
    echo "❌ Error: Git no está instalado. Por favor, instálalo y vuelve a intentarlo."
    exit 1
fi

echo "-----------------------------------------"
echo "Iniciando backup automático a las: $(date)"
echo "Directorio actual: $(pwd)"
echo "-----------------------------------------"

# Configuración: URL del repositorio remoto y branch a usar
REPO_URL="https://github.com/elvenaz0/Almacen-de-scripts-para-azure-y-aws.git"
BRANCH="master"  # Cambia este valor por el branch que desees clonar y usar

# Obtener la fecha y hora actuales de forma dinámica
FECHA=$(date '+%Y-%m-%d %H:%M:%S')
MENSAJE="Backup automático - $FECHA"

echo "📅 Fecha y hora actuales: $FECHA"
echo "🌿 Branch seleccionado: $BRANCH"

# Verificar si el directorio actual es un repositorio Git
if [ ! -d ".git" ]; then
    echo "❌ No se encontró un repositorio Git en este directorio."
    # Si el directorio 'repo_temp' ya existe, se ingresa en él; de lo contrario, se clona el repositorio
    if [ -d "repo_temp" ]; then
        echo "📂 El directorio 'repo_temp' ya existe. Entrando en 'repo_temp'..."
        cd repo_temp || { echo "⚠️ Error: No se pudo acceder al directorio 'repo_temp'."; exit 1; }
    else
        echo "⏬ Clonando el repositorio en el branch '$BRANCH' desde $REPO_URL en el directorio 'repo_temp'..."
        git clone --branch "$BRANCH" "$REPO_URL" repo_temp || { echo "⚠️ Error: Clonación del repositorio falló."; exit 1; }
        cd repo_temp || { echo "⚠️ Error: No se pudo acceder al directorio clonado 'repo_temp'."; exit 1; }
    fi
else
    echo "🔍 Se detectó un repositorio Git en el directorio actual."
fi

# Cambiar a la rama especificada (en caso de que no se haya clonado con el branch deseado)
echo "🔄 Cambiando a la rama '$BRANCH'..."
if git checkout "$BRANCH"; then
    echo "✅ Cambio a la rama '$BRANCH' completado."
else
    echo "⚠️ Error: Falló el cambio a la rama '$BRANCH'."
    exit 1
fi

# Actualizar el repositorio para obtener los últimos cambios
echo "⏫ Actualizando el repositorio (git pull)..."
if git pull origin "$BRANCH"; then
    echo "✅ Repositorio actualizado."
else
    echo "⚠️ Error: No se pudieron traer los cambios del repositorio remoto."
    exit 1
fi

# Agregar todos los archivos nuevos y modificados
echo "➕ Agregando archivos (git add)..."
git add -A

# Realizar commit con el mensaje que incluye la fecha y hora actual
echo "💬 Realizando commit con mensaje: \"$MENSAJE\""
if git commit -m "$MENSAJE"; then
    echo "✅ Commit realizado correctamente."
else
    echo "⚠️ Advertencia: No se realizaron cambios o el commit falló."
fi

# Enviar los cambios al repositorio remoto
echo "🚀 Realizando push a la rama '$BRANCH'..."
if git push origin "$BRANCH"; then
    echo "✅ Push realizado con éxito."
else
    echo "⚠️ Error: El push a '$BRANCH' falló."
    exit 1
fi

echo "-----------------------------------------"
echo "✅ Backup completado con éxito a las: $(date)"
echo "-----------------------------------------"

# Pausa para permitir visualizar la salida (útil si se ejecuta haciendo doble clic)
read -p "Presione Enter para finalizar..."
