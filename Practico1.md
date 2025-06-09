# 🧪 Práctica Semanal - Semana 5: Procesos y administración del sistema

## 🎯 Objetivo
Programar una tarea automática con `cron` que realice un respaldo comprimido de una carpeta del usuario.

---

## 🔧 Paso 1: Crear el script de respaldo

```bash
nano ~/backup.sh
```
Contenido del archivo:

```bash
#!/bin/bash

# Ruta de origen
ORIGEN="/home/$USER/documentos"

# Ruta de destino con fecha
DESTINO="/home/$USER/respaldo_$(date +%F).tar.gz"

# Crear respaldo comprimido
tar -czf "$DESTINO" "$ORIGEN"
```
🧠 Explicación del comando tar:
-c: Crea un nuevo archivo.

-z: Comprime con gzip.

-f: Usa el nombre de archivo indicado.

$(date +%F): Inserta la fecha actual en formato YYYY-MM-DD.

🔧 Paso 2: Dar permisos de ejecución

```bash
chmod +x ~/backup.sh
```
🔧 Paso 3: Programar tarea con cron
Editamos las tareas programadas del usuario:

```bash

crontab -e
```
Agregamos esta línea:

```bash

30 3 * * * /home/$USER/backup.sh
```
🕒 Esto ejecuta el script todos los días a las 3:30 AM.

🖼️ Verificación
Verificar tareas:

```bash


crontab -l
```
Verificar respaldo creado:

```bash

ls -lh ~/respaldo_*.tar.gz
```
📷 Evidencias requeridas
Captura del crontab -l

Captura del archivo .tar.gz en la carpeta del usuario

Historial del Bash, history 
✅ Resultado esperado
Script automatizado en funcionamiento

Archivo .tar.gz diario en la carpeta del usuario con nombre respaldo_YYYY-MM-DD.tar.gz
