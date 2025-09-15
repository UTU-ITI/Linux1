#!/bin/bash

# Cargar variables desde el .env
if [ ! -f ".env" ]; then
  echo "❌ Archivo .env no encontrado."
  exit 1
fi
export $(grep -v '^#' .env | xargs)

# Crear el usuario si no existe
if id "$SYSTEM_USER" &>/dev/null; then
  echo "✅ Usuario $SYSTEM_USER ya existe"
else
  sudo adduser --disabled-password --gecos "" "$SYSTEM_USER"
  echo "🔧 Usuario $SYSTEM_USER creado"
fi

# Instalar Apache, PHP y MySQL Server
echo "📦 Instalando Apache, PHP y MySQL..."
sudo apt update
sudo apt install -y apache2 php libapache2-mod-php mysql-server git unzip

# Clonar el repositorio en public_html
USER_HOME="/home/$SYSTEM_USER"
WEB_DIR="$USER_HOME/public_html"

sudo -u "$SYSTEM_USER" mkdir -p "$WEB_DIR"
sudo -u "$SYSTEM_USER" git clone "$GIT_REPO" "$WEB_DIR"

# Establecer permisos
sudo chown -R "$SYSTEM_USER":"$SYSTEM_USER" "$WEB_DIR"

# Configurar Apache virtual host
VHOST_FILE="/etc/apache2/sites-available/${SYSTEM_USER}.conf"
sudo tee "$VHOST_FILE" > /dev/null <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot $WEB_DIR
    <Directory $WEB_DIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/${SYSTEM_USER}_error.log
    CustomLog \${APACHE_LOG_DIR}/${SYSTEM_USER}_access.log combined
</VirtualHost>
EOF

sudo a2ensite "${SYSTEM_USER}.conf"
sudo a2dissite 000-default.conf
sudo systemctl reload apache2

# Configurar MySQL si hay datos
if [ -n "$DB_NAME" ]; then
  echo "📂 Configurando base de datos MySQL..."
  
  sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

  echo "✅ Base de datos $DB_NAME y usuario $DB_USER configurados."
fi

# Reiniciar Apache
sudo systemctl restart apache2
# Habilitar userdir
a2enmod userdir
systemctl restart apache2

# Configurar directorio web para el usuario
USER_HOME=$(eval echo ~$USER_NAME)
WEB_PATH="$USER_HOME/$WEB_DIR"

mkdir -p "$WEB_PATH"
chown -R $USER_NAME:$USER_NAME "$WEB_PATH"
chmod 755 "$USER_HOME"
echo "🎉 Instalación y configuración completa. Sitio funcionando en http://localhost/"
