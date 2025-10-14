#!/bin/bash

# Nombre del proyecto para el log en Syslog
PROYECTO="MONITOR_DB_TOM"

# --- CONFIGURACIÓN DE RUTAS ---
# Reemplaza con la ruta real a tu directorio y archivo .env
DOTENV_FILE="/ruta/a/tu/proyecto/.env" 
MONITOR_DIR="/ruta/al/directorio/a/monitorear" # Reemplaza con la ruta real

# --- CONFIGURACIÓN DEL BUCLE ---
INTERVALO=5 # Tiempo de espera en segundos
TABLE_NAME="nombre_de_tu_tabla" # Reemplaza con el nombre de la tabla

# --- FUNCIÓN PARA REGISTRAR EN SYSLOG ---
# Usa la facilidad local0 y el nivel info/err
log_message() {
    local NIVEL="$1" # e.g., 'info', 'err', 'warning'
    local MENSAJE="$2"
    logger -t "$PROYECTO" -p "local0.$NIVEL" -- "$MENSAJE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$NIVEL] $MENSAJE" # También imprime en la consola
}

# --- 1. CARGAR VARIABLES DE ENTORNO (.ENV) ---
# Método simple de 'sourcing' para cargar variables desde .env
if [ -f "$DOTENV_FILE" ]; then
    log_message "info" "Cargando variables desde $DOTENV_FILE..."
    # Exporta las variables para que estén disponibles para el script
    export $(grep -v '^#' "$DOTENV_FILE" | xargs)
else
    log_message "err" "ERROR: Archivo .env no encontrado en $DOTENV_FILE. Saliendo."
    exit 1
fi

# --- 2. VERIFICAR VARIABLES DE LA BD ---
if [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ]; then
    log_message "err" "ERROR: Faltan variables de base de datos (DB_USER, DB_PASS, DB_NAME) en el archivo .env. Saliendo."
    exit 1
fi

# Las variables DB_USER, DB_PASS y DB_NAME ahora están cargadas desde el .env
DB_USER_VAL=$DB_USER
DB_PASS_VAL=$DB_PASS
DB_NAME_VAL=$DB_NAME

# --- FUNCIÓN PARA INSERTAR DATOS ---
insertar_datos() {
    local ARCHIVO="$1"
    local NOMBRE_BASE
    local FECHA SN ESTADO

    # Obtener solo el nombre del archivo (sin ruta) y quitar la extensión .tom
    NOMBRE_BASE=$(basename "$ARCHIVO" .tom)

    # Extraer las variables (Fecha, SN, Estado) usando guiones como delimitadores
    IFS='-' read -r FECHA SN ESTADO <<< "$NOMBRE_BASE"
    
    # Validación básica del patrón de nombre
    if [ -z "$FECHA" ] || [ -z "$SN" ] || [ -z "$ESTADO" ]; then
        log_message "warning" "Advertencia: El archivo '$NOMBRE_BASE.tom' no sigue el formato FECHA-SN-ESTADO. Saltando."
        return 1
    fi

    # Preparar la consulta SQL
    CONSULTA_SQL="INSERT INTO $TABLE_NAME (Fecha, SN, Estado) VALUES ('$FECHA', '$SN', '$ESTADO');"

    log_message "info" "Insertando: Fecha='$FECHA', SN='$SN', Estado='$ESTADO' del archivo $NOMBRE_BASE.tom"
    
    # Ejecutar la inserción en MySQL
    if mysql -u "$DB_USER_VAL" -p"$DB_PASS_VAL" "$DB_NAME_VAL" -e "$CONSULTA_SQL" 2> /dev/null; then
        log_message "info" "✅ Inserción exitosa. Eliminando archivo: $ARCHIVO"
        # Eliminar el archivo después de una inserción exitosa
        rm "$ARCHIVO"
    else
        # Captura errores de MySQL o de conexión
        log_message "err" "❌ Error al insertar datos para el archivo: $ARCHIVO. (Verifique credenciales y conexión a MySQL)."
        # Opcional: mover el archivo a un directorio de errores para inspección
        # mv "$ARCHIVO" "$MONITOR_DIR/errores/" 
    fi
}

# --- BUCLE PRINCIPAL ---
log_message "info" "Monitoreo iniciado en $MONITOR_DIR cada $INTERVALO segundos."

while true; do
    
    # Buscar archivos que terminen en .tom en el directorio y que sigan el patrón básico
    # -maxdepth 1 asegura que solo busca en el directorio de monitoreo y no en subdirectorios
    find "$MONITOR_DIR" -maxdepth 1 -type f -name '*-*-*.tom' -print0 | while IFS= read -r -d $'\0' archivo; do
        insertar_datos "$archivo"
    done
    
    sleep "$INTERVALO"
done