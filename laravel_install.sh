#!/bin/bash
set -e

# Cargar variables del .env
if [ ! -f .env ]; then
    echo "❌ Archivo .env no encontrado"
    exit 1
fi
export $(grep -v '^#' .env | xargs)

# Crear usuario si no existe
if id "$USER_NAME" &>/dev/null; then
    echo "ℹ️ Usuario $USER_NAME ya existe"
else
    echo "➕ Creando usuario $USER_NAME"
    useradd -m -s /bin/bash "$USER_NAME"
    echo "$USER_NAME:$USER_PASS" | chpasswd
fi

# Instalar dependencias
echo "📦 Instalando paquetes necesarios..."
apt update
apt install -y apache2 php php-cli php-mysql libapache2-mod-php \
    composer unzip mysql-server php-xml php-mbstring php-curl

# Habilitar userdir y rewrite
a2enmod userdir
a2enmod rewrite
systemctl restart apache2

# Crear carpeta web del usuario
USER_HOME=$(eval echo ~$USER_NAME)
WEB_PATH="$USER_HOME/$WEB_ROOT"
APP_PATH="$USER_HOME/$APP"

mkdir -p "$WEB_PATH"
mkdir -p "$APP_PATH"
chown -R $USER_NAME:$USER_NAME "$WEB_PATH" "$APP_PATH"

# Configurar permisos correctos
chmod 755 "$USER_HOME"
chmod -R 755 "$WEB_PATH"

# Instalar Laravel
sudo -u "$USER_NAME" bash <<EOF
cd "$APP_PATH"
composer create-project laravel/laravel .
EOF

# Configurar base de datos
echo "📂 Configurando base de datos..."
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Configurar .env de Laravel
LARAVEL_ENV="$APP_PATH/.env"
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" $LARAVEL_ENV
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" $LARAVEL_ENV
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" $LARAVEL_ENV

# Migraciones iniciales
sudo -u "$USER_NAME" bash <<EOF
cd "$APP_PATH"
php artisan migrate
EOF

echo "✅ Instalación completada"
echo "🌐 Acceso web: http://localhost/~$USER_NAME"
