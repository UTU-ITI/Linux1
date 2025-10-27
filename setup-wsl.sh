#!/bin/bash

################################################################################
# Setup Docker + Docker Compose en WSL Ubuntu 24.04
# Script minimalista desde cero
################################################################################

set -e

# Colores
G='\033[0;32m' Y='\033[1;33m' R='\033[0;31m' B='\033[0;34m' NC='\033[0m'

log() { echo -e "${G}[✓]${NC} $*"; }
info() { echo -e "${B}[→]${NC} $*"; }
warn() { echo -e "${Y}[!]${NC} $*"; }
error() { echo -e "${R}[✗]${NC} $*" >&2; exit 1; }

banner() {
    clear
    cat <<'EOF'
╔══════════════════════════════════════════════════════════╗
║     Docker + Docker Compose Setup para WSL              ║
║     Ubuntu 24.04 (Noble Numbat)                          ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo ""
}

# ============================================================================
# VERIFICAR ENTORNO WSL
# ============================================================================

check_wsl() {
    info "Verificando entorno WSL..."
    
    # Verificar si estamos en WSL
    if ! grep -qi microsoft /proc/version; then
        error "Este script está diseñado para WSL. No se detectó WSL."
    fi
    
    # Obtener versión WSL
    if grep -qi "WSL2" /proc/version; then
        WSL_VERSION="2"
        log "WSL 2 detectado ✓"
    else
        WSL_VERSION="1"
        warn "WSL 1 detectado. Se recomienda WSL 2 para mejor rendimiento."
    fi
    
    # Verificar Ubuntu version
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$VERSION_ID" == "24.04" ]]; then
            log "Ubuntu 24.04 confirmado ✓"
        else
            warn "Ubuntu $VERSION_ID detectado. Este script está optimizado para 24.04."
        fi
    fi
}

# ============================================================================
# VERIFICAR SYSTEMD
# ============================================================================

check_systemd() {
    info "Verificando systemd..."
    
    # En WSL2, systemd puede estar habilitado
    if command -v systemctl &>/dev/null && systemctl status &>/dev/null; then
        SYSTEMD_AVAILABLE=true
        log "systemd está disponible y funcionando"
    else
        SYSTEMD_AVAILABLE=false
        warn "systemd no está disponible. Docker se iniciará manualmente."
        
        # Crear archivo de configuración para habilitar systemd
        cat <<'EOFSYSTEMD'

Para habilitar systemd en WSL 2, crea/edita el archivo:
  /etc/wsl.conf

Y añade:
  [boot]
  systemd=true

Luego reinicia WSL desde PowerShell:
  wsl --shutdown

Después vuelve a ejecutar este script.
EOFSYSTEMD
        
        read -rp "¿Deseas continuar sin systemd? (requiere inicio manual) [s/N]: " continue_without
        if [[ "${continue_without,,}" != "s" ]]; then
            exit 0
        fi
    fi
}

# ============================================================================
# ACTUALIZAR SISTEMA
# ============================================================================

update_system() {
    info "Actualizando sistema..."
    sudo apt-get update -qq
    sudo apt-get upgrade -y -qq
    log "Sistema actualizado"
}

# ============================================================================
# INSTALAR DEPENDENCIAS
# ============================================================================

install_dependencies() {
    info "Instalando dependencias..."
    
    sudo apt-get install -y -qq \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        software-properties-common
    
    log "Dependencias instaladas"
}

# ============================================================================
# INSTALAR DOCKER
# ============================================================================

install_docker() {
    info "Instalando Docker..."
    
    # Eliminar versiones antiguas si existen
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Añadir clave GPG oficial de Docker
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    
    # Configurar repositorio
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instalar Docker Engine
    sudo apt-get update -qq
    sudo apt-get install -y -qq \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
    
    log "Docker instalado: $(docker --version 2>/dev/null || echo 'pendiente de iniciar')"
}

# ============================================================================
# CONFIGURAR DOCKER PARA WSL
# ============================================================================

configure_docker() {
    info "Configurando Docker para WSL..."
    
    # Añadir usuario al grupo docker
    sudo usermod -aG docker "$USER"
    log "Usuario $USER añadido al grupo docker"
    
    # Configurar daemon de Docker
    sudo mkdir -p /etc/docker
    
    sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "dns": ["8.8.8.8", "8.8.4.4"]
}
EOF
    
    log "Configuración de Docker aplicada"
}

# ============================================================================
# INICIAR DOCKER
# ============================================================================

start_docker() {
    info "Iniciando Docker..."
    
    if [[ "$SYSTEMD_AVAILABLE" == true ]]; then
        # Con systemd
        sudo systemctl enable docker
        sudo systemctl start docker
        log "Docker iniciado con systemd"
    else
        # Sin systemd - inicio manual
        if ! pgrep -x dockerd > /dev/null; then
            sudo dockerd > /dev/null 2>&1 &
            sleep 3
            log "Docker daemon iniciado manualmente"
        else
            log "Docker daemon ya está corriendo"
        fi
    fi
    
    # Verificar que Docker funciona
    if sudo docker run --rm hello-world > /dev/null 2>&1; then
        log "Docker está funcionando correctamente ✓"
    else
        error "Docker no pudo iniciar correctamente"
    fi
}

# ============================================================================
# VERIFICAR DOCKER COMPOSE
# ============================================================================

verify_docker_compose() {
    info "Verificando Docker Compose..."
    
    # Docker Compose v2 viene como plugin
    if docker compose version &>/dev/null; then
        local compose_version=$(docker compose version --short)
        log "Docker Compose v2 instalado: $compose_version"
        log "Usa: 'docker compose' (sin guión)"
    else
        warn "Docker Compose no disponible"
    fi
}

# ============================================================================
# CREAR SCRIPT DE INICIO AUTOMÁTICO
# ============================================================================

create_startup_script() {
    if [[ "$SYSTEMD_AVAILABLE" == true ]]; then
        return 0
    fi
    
    info "Creando script de inicio automático..."
    
    # Script para iniciar Docker manualmente
    cat > ~/start-docker.sh <<'EOF'
#!/bin/bash
# Script para iniciar Docker en WSL sin systemd

if ! pgrep -x dockerd > /dev/null; then
    echo "Iniciando Docker..."
    sudo dockerd > /dev/null 2>&1 &
    sleep 3
    echo "Docker iniciado"
else
    echo "Docker ya está corriendo"
fi
EOF
    
    chmod +x ~/start-docker.sh
    
    # Añadir al .bashrc para inicio automático (opcional)
    if ! grep -q "start-docker.sh" ~/.bashrc; then
        cat >> ~/.bashrc <<'EOF'

# Auto-start Docker en WSL (si no usa systemd)
if ! pgrep -x dockerd > /dev/null && [ -f ~/start-docker.sh ]; then
    ~/start-docker.sh
fi
EOF
        log "Script de inicio añadido a .bashrc"
    fi
    
    log "Script creado: ~/start-docker.sh"
}

# ============================================================================
# CREAR PROYECTO DE PRUEBA
# ============================================================================

create_test_project() {
    info "Creando proyecto de prueba..."
    
    local test_dir="$HOME/docker-test"
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    # Crear docker-compose.yml de prueba
    cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  web:
    image: nginx:alpine
    container_name: test-nginx
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    restart: unless-stopped

  whoami:
    image: traefik/whoami
    container_name: test-whoami
    ports:
      - "8081:80"
EOF
    
    # Crear página HTML de prueba
    mkdir -p html
    cat > html/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Docker en WSL - Funcionando!</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            text-align: center;
            background: rgba(255,255,255,0.1);
            padding: 50px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
        }
        h1 { font-size: 3em; margin: 0; }
        p { font-size: 1.5em; }
        .success { color: #4ade80; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 Docker + WSL</h1>
        <p class="success">✓ Funcionando Correctamente!</p>
        <p>Ubuntu 24.04 en WSL</p>
        <p>Docker + Docker Compose instalados</p>
    </div>
</body>
</html>
EOF
    
    log "Proyecto de prueba creado en: $test_dir"
}

# ============================================================================
# PRUEBAS FINALES
# ============================================================================

run_tests() {
    info "Ejecutando pruebas..."
    
    # Test 1: Docker info
    if sudo docker info > /dev/null 2>&1; then
        log "Test 1: Docker info ✓"
    else
        warn "Test 1: Docker info ✗"
    fi
    
    # Test 2: Ejecutar contenedor
    if sudo docker run --rm busybox echo "Test exitoso" > /dev/null 2>&1; then
        log "Test 2: Ejecutar contenedor ✓"
    else
        warn "Test 2: Ejecutar contenedor ✗"
    fi
    
    # Test 3: Docker Compose
    cd "$HOME/docker-test"
    if docker compose config > /dev/null 2>&1; then
        log "Test 3: Docker Compose config ✓"
    else
        warn "Test 3: Docker Compose config ✗"
    fi
}

# ============================================================================
# INSTRUCCIONES FINALES
# ============================================================================

print_instructions() {
    echo ""
    log "╔══════════════════════════════════════════════════════════╗"
    log "║  INSTALACIÓN COMPLETADA                                  ║"
    log "╚══════════════════════════════════════════════════════════╝"
    echo ""
    
    echo -e "${B}Docker instalado:${NC}"
    sudo docker --version
    echo ""
    
    echo -e "${B}Docker Compose instalado:${NC}"
    docker compose version
    echo ""
    
    if [[ "$SYSTEMD_AVAILABLE" == true ]]; then
        echo -e "${G}✓ Docker se inicia automáticamente con systemd${NC}"
        echo ""
        echo -e "${B}Comandos útiles:${NC}"
        echo "  sudo systemctl status docker    # Ver estado"
        echo "  sudo systemctl restart docker   # Reiniciar"
        echo "  sudo systemctl stop docker      # Detener"
    else
        echo -e "${Y}⚠ Docker requiere inicio manual${NC}"
        echo ""
        echo -e "${B}Para iniciar Docker:${NC}"
        echo "  ~/start-docker.sh"
        echo ""
        echo -e "${B}O manualmente:${NC}"
        echo "  sudo dockerd &"
    fi
    
    echo ""
    echo -e "${B}Proyecto de prueba:${NC}"
    echo "  cd ~/docker-test"
    echo "  docker compose up -d"
    echo "  "
    echo "  Luego abre en Windows:"
    echo "  • http://localhost:8080  (Nginx)"
    echo "  • http://localhost:8081  (Whoami)"
    echo ""
    
    echo -e "${Y}IMPORTANTE:${NC}"
    echo "  1. Cierra y vuelve a abrir la terminal WSL"
    echo "     (para que el grupo 'docker' se aplique)"
    echo "  "
    echo "  2. Después podrás usar Docker sin 'sudo':"
    echo "     docker ps"
    echo "     docker compose up"
    echo ""
    
    if [[ "$SYSTEMD_AVAILABLE" != true ]]; then
        echo -e "${B}Para habilitar systemd (recomendado):${NC}"
        echo "  1. Crea el archivo /etc/wsl.conf:"
        echo "     sudo nano /etc/wsl.conf"
        echo "  "
        echo "  2. Añade:"
        echo "     [boot]"
        echo "     systemd=true"
        echo "  "
        echo "  3. Desde PowerShell en Windows:"
        echo "     wsl --shutdown"
        echo "  "
        echo "  4. Vuelve a abrir Ubuntu"
        echo ""
    fi
    
    echo -e "${G}Comandos Docker básicos:${NC}"
    echo "  docker ps                    # Ver contenedores"
    echo "  docker images                # Ver imágenes"
    echo "  docker compose up -d         # Iniciar proyecto"
    echo "  docker compose down          # Detener proyecto"
    echo "  docker compose logs -f       # Ver logs"
    echo ""
}

# ============================================================================
# FUNCIÓN PRINCIPAL
# ============================================================================

main() {
    banner
    
    # Verificaciones
    check_wsl
    check_systemd
    
    echo ""
    read -rp "¿Iniciar instalación de Docker? [S/n]: " start_install
    if [[ "${start_install,,}" == "n" ]]; then
        exit 0
    fi
    
    echo ""
    
    # Instalación
    update_system
    install_dependencies
    install_docker
    configure_docker
    start_docker
    verify_docker_compose
    
    # Configuración adicional
    create_startup_script
    create_test_project
    
    # Verificaciones
    run_tests
    
    # Instrucciones finales
    print_instructions
}

# Verificar que se ejecuta con permisos suficientes
if ! sudo -n true 2>/dev/null; then
    error "Este script requiere permisos sudo"
fi

# Ejecutar
main "$@"