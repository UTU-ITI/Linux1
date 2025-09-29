#!/bin/bash

# Nombre del proyecto para el log en Syslog
PROYECTO="MONITOR_DB_TOM"

# --- CONFIGURACIÓN DE RUTAS ---
DOTENV_FILE="/ruta/a/tu/proyecto/.env" 
MONITOR_DIR="/ruta/al/directorio/a/monitorear" # Reemplaza con la ruta real
TABLE_NAME="nombre_de_tu_tabla" # Reemplaza con el nombre de la tabla

# Código de error común de MySQL para violación de clave foránea (Foreign Key)
# Este error indica que el SN (clave foránea) no existe en la tabla de referencia.
ERROR_CODE_FK="1452" 

# --- FUNCIÓN PARA REGISTRAR EN SYSLOG ---
log_message() {
    local NIVEL="$1"
    local MENSAJE="$2"
    # Registra en syslog
    logger -t "$PROYECTO" -p "local0.$NIVEL" -- "$MENSAJE"
    # También imprime en la consola para depuración
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$NIVEL] $MENSAJE"
}

# --- FUNCIÓN PARA ENVIAR CORREO DE ERROR ---
enviar_email_error() {
    local SN="$1"
    local ARCHIVO="$2"
    local ERROR_MSG="$3"
    local ASUNTO="[ALERTA $PROYECTO] SN NO ENCONTRADO DURANTE INSERCIÓN"
    
    # Cuerpo del correo
    local CUERPO="Ha ocurrido un error de Clave Foránea (SN no existente) en la base de datos.\n"
    CUERPO+="----------------------------------------------------------------------\n"
    CUERPO+="Archivo de origen: $ARCHIVO\n"
    CUERPO+="Serial Number (SN) no encontrado: $SN\n"
    CUERPO+="Mensaje de error completo de MySQL:\n"
    CUERPO+="$ERROR_MSG\n"
    CUERPO+="----------------------------------------------------------------------\n"
    CUERPO+="Fecha de la alerta: $(date)\n"

    log_message "warning" "Enviando alerta por correo a $MAIL_RECIPIENT. SN: $SN"

    # Envío del correo usando la utilidad 'mail'
    # La variable MAIL_SENDER se usa con la opción -r (remitente)
    echo -e "$CUERPO" | mail -s "$ASUNTO" -r "$MAIL_SENDER" "$MAIL_RECIPIENT"

    if [ $? -eq 0 ]; then
        log_message "info" "Correo de alerta enviado exitosamente."
    else
        log_message "err" "FALLO al enviar el correo. Verifique la configuración del MTA local (sendmail/postfix)."
    fi
}

# --- 1. CARGAR VARIABLES DE ENTORNO (.ENV) ---
if [ -f "$DOTENV_FILE" ]; then
    log_message "info" "Cargando variables desde $DOTENV_FILE..."
    export $(grep -v '^#' "$DOTENV_FILE" | xargs)
else
    log_message "err" "ERROR: Archivo .env no encontrado en $DOTENV_FILE. Saliendo."
    exit 1
fi

# --- 2. VERIFICAR VARIABLES CLAVE ---
if [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DB_NAME" ] || [ -z "$MAIL_RECIPIENT" ] || [ -z "$MAIL_SENDER" ]; then
    log_message "err" "ERROR: Faltan variables clave (BD o MAIL) en .env. Saliendo."
    exit 1
fi

# Asignar a variables locales para mayor claridad
DB_USER_VAL=$DB_USER
DB_PASS_VAL=$DB_PASS
DB_NAME_VAL=$DB_NAME
MAIL_RECIPIENT=$MAIL_RECIPIENT
MAIL_SENDER=$MAIL_SENDER

# --- FUNCIÓN PARA INSERTAR DATOS ---
insertar_datos() {
    local ARCHIVO="$1"
    local NOMBRE_BASE
    local FECHA SN ESTADO
    
    NOMBRE_BASE=$(basename "$ARCHIVO" .tom)
    IFS='-' read -r FECHA SN ESTADO <<< "$NOMBRE_BASE"
    
    if [ -z "$FECHA" ] || [ -z "$SN" ] || [ -z "$ESTADO" ]; then
        log_message "warning" "Advertencia: Archivo '$NOMBRE_BASE.tom' no sigue el formato esperado. Saltando."
        return 1
    fi

    local CONSULTA_SQL="INSERT INTO $TABLE_NAME (Fecha, SN, Estado) VALUES ('$FECHA', '$SN', '$ESTADO');"
    local RESULTADO_MYSQL_ERROR 
    
    log_message "info" "Intentando insertar datos del archivo: $NOMBRE_BASE.tom"
    
    # Ejecutar la inserción:
    # 1>&2 redirige stdout de mysql a stderr para que 'RESULTADO_MYSQL_ERROR' contenga solo el error.
    # El status de salida ($?) aún reflejará el éxito (0) o el fallo (no 0).
    RESULTADO_MYSQL_ERROR=$(mysql -u "$DB_USER_VAL" -p"$DB_PASS_VAL" "$DB_NAME_VAL" -e "$CONSULTA_SQL" 2>&1 >/dev/null)
    local EXIT_STATUS=$?

    if [ $EXIT_STATUS -eq 0 ]; then
        log_message "info" "✅ Inserción exitosa. Eliminando archivo: $ARCHIVO"
        rm "$ARCHIVO"
    else
        # --- MANEJO DE ERRORES ---
        # Si el error es una violación de clave foránea (SN no existente)
        if echo "$RESULTADO_MYSQL_ERROR" | grep -q "ERROR $ERROR_CODE_FK"; then
            log_message "err" "❌ ERROR DE FK detectado para SN: $SN."
            enviar_email_error "$SN" "$ARCHIVO" "$RESULTADO_MYSQL_ERROR"
            # Opcional: Mover el archivo a un directorio de error después del email
            # mv "$ARCHIVO" "$MONITOR_DIR/errores/"
        else
            # Cualquier otro error (ej: credenciales, conexión, error de sintaxis SQL)
            log_message "err" "❌ ERROR DESCONOCIDO. Archivo: $ARCHIVO. Mensaje: $RESULTADO_MYSQL_ERROR"
        fi
    fi
}

# --- BUCLE PRINCIPAL ---
log_message "info" "Monitoreo iniciado en $MONITOR_DIR cada $INTERVALO segundos."

while true; do
    find "$MONITOR_DIR" -maxdepth 1 -type f -name '*-*-*.tom' -print0 | while IFS= read -r -d $'\0' archivo; do
        insertar_datos "$archivo"
    done
    
    sleep "$INTERVALO"
done