#!/bin/bash

# --- CONFIGURACIÓN DE LA BASE DE DATOS Y DIRECTORIO ---
DB_USER="tu_usuario_mysql"        # Reemplaza con tu usuario de MySQL
DB_PASS="tu_contraseña_mysql"     # Reemplaza con tu contraseña de MySQL
DB_NAME="nombre_de_tu_base_de_datos" # Reemplaza con el nombre de la BD
TABLE_NAME="nombre_de_tu_tabla"  # Reemplaza con el nombre de la tabla
MONITOR_DIR="/ruta/al/directorio/a/monitorear" # Reemplaza con la ruta real

# --- CONFIGURACIÓN DEL BUCLE ---
INTERVALO=5 # Tiempo de espera en segundos

# --- FUNCIÓN PARA INSERTAR DATOS ---
insertar_datos() {
    local ARCHIVO="$1"
    local NOMBRE_BASE
    local FECHA SN ESTADO

    # 1. Obtener solo el nombre del archivo (sin ruta) y quitar la extensión .tom
    NOMBRE_BASE=$(basename "$ARCHIVO" .tom)

    # 2. Extraer las variables (Fecha, SN, Estado) usando guiones como delimitadores
    # Se usa IFS para dividir la cadena basada en '-'
    IFS='-' read -r FECHA SN ESTADO <<< "$NOMBRE_BASE"

    # 3. Preparar la consulta SQL
    # Asegúrate de que los campos en tu tabla (Fecha, SN, Estado)
    # son del tipo adecuado (VARCHAR, DATE, etc.)
    # Se usa el comando mysql con la opción -e para ejecutar la consulta directamente.
    
    # IMPORTANTE: Asegúrate de que tu columna 'Fecha' pueda almacenar el formato de fecha 
    # que esperas (YYYYMMDD o similar). Si usas el tipo DATE, es mejor
    # formatearlo antes de la inserción, pero si solo almacenas la cadena,
    # el tipo VARCHAR es suficiente. Aquí asumimos VARCHAR.
    
    CONSULTA_SQL="INSERT INTO $TABLE_NAME (Fecha, SN, Estado) VALUES ('$FECHA', '$SN', '$ESTADO');"

    echo "Intentando insertar: Fecha='$FECHA', SN='$SN', Estado='$ESTADO'"
    
    # Ejecutar la inserción en MySQL
    if mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$CONSULTA_SQL"; then
        echo "✅ Inserción exitosa para el archivo: $ARCHIVO"
        # 4. Mover/Eliminar el archivo después de una inserción exitosa
        # Se recomienda moverlo a un directorio 'procesado' en lugar de eliminarlo
        # para propósitos de auditoría/depuración.
        # mkdir -p "$MONITOR_DIR/procesado" 
        # mv "$ARCHIVO" "$MONITOR_DIR/procesado/"
        
        # Si prefieres solo eliminarlo:
        rm "$ARCHIVO"
        echo "Archivo eliminado: $ARCHIVO"
    else
        echo "❌ Error en la inserción para el archivo: $ARCHIVO"
        # Manejo de errores: podrías moverlo a un directorio 'errores' aquí
    fi
}

# --- BUCLE PRINCIPAL ---
echo "Iniciando monitoreo del directorio $MONITOR_DIR cada $INTERVALO segundos..."
while true; do
    echo "--- $(date) - Buscando archivos ---"
    
    # Buscar archivos que terminen en .tom en el directorio
    # y que sigan el patrón básico (e.g., al menos 2 guiones)
    # Se utiliza find para un manejo más robusto.
    find "$MONITOR_DIR" -maxdepth 1 -type f -name '*-*-*.tom' -print0 | while IFS= read -r -d $'\0' archivo; do
        insertar_datos "$archivo"
    done
    
    echo "Esperando $INTERVALO segundos..."
    sleep $INTERVALO
done