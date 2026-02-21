#!/bin/bash
clear
IP=$(wget -qO- ipv4.icanhazip.com)
[[ "$(whoami)" != "root" ]] && {
echo
echo "¡NECESITAS EJECUTAR LA INSTALACIÓN COMO ROOT!"
echo
rm install.sh
exit 0
}

# ==============================================
# DETECCIÓN DE SISTEMA OPERATIVO
# ==============================================
echo "🔍 Detectando sistema operativo..."

# Actualizar e instalar lsb-release (útil para Ubuntu)
apt-get update -y > /dev/null 2>&1
apt-get install -y lsb-release > /dev/null 2>&1

if [ -f /etc/debian_version ]; then
    # Es un sistema basado en Debian
    if [ -f /etc/lsb-release ]; then
        # Es Ubuntu
        ubuntuV=$(lsb_release -r | awk '{print $2}' | cut -d. -f1)
        if [[ $(($ubuntuV < 20)) = 1 ]]; then
            clear
            echo "❌ EN UBUNTU NECESITAS VERSIÓN 20.04 O 22.04"
            echo "   TU VERSIÓN: $ubuntuV"
            echo
            rm /root/install.sh
            exit 0
        fi
        echo "✅ Ubuntu $ubuntuV detectado (compatible)"
    else
        # Es Debian puro
        debianV=$(cat /etc/debian_version | cut -d. -f1)
        if [[ $debianV -lt 11 ]]; then
            clear
            echo "❌ EN DEBIAN NECESITAS VERSIÓN 11 O SUPERIOR"
            echo "   TU VERSIÓN: $debianV"
            echo
            rm /root/install.sh
            exit 0
        fi
        echo "✅ Debian $debianV detectado (compatible)"
    fi
else
    clear
    echo "❌ SISTEMA NO SOPORTADO"
    echo "   USA UBUNTU 20.04+, 22.04+ O DEBIAN 11+"
    echo
    rm /root/install.sh
    exit 0
fi

# ==============================================
# VERIFICAR SI YA ESTÁ INSTALADO
# ==============================================
[[ -e /root/paineldtunnel/src/index.ts ]] && {
  clear
  echo "EL PANEL YA ESTÁ INSTALADO. ¿DESEAS ELIMINARLO? (s/n)"
  read remo
  [[ $remo = @(s|S) ]] && {
  cd /root/paineldtunnel
  rm -r painelbackup > /dev/null 2>&1
  mkdir painelbackup > /dev/null 2>&1
  cp prisma/database.db painelbackup 2>/dev/null
  cp .env painelbackup 2>/dev/null
  zip -r painelbackup.zip painelbackup > /dev/null 2>&1
  mv painelbackup.zip /root 2>/dev/null
  rm -rf /root/paineldtunnel 2>/dev/null
  rm /root/install.sh 2>/dev/null
  echo "¡Eliminado con éxito! (backup en /root/painelbackup.zip)"
  exit 0
  }
  exit 0
}

# ==============================================
# SOLICITAR PUERTO
# ==============================================
clear
echo "¿QUÉ PUERTO DESEAS ACTIVAR?"
read porta
echo
echo "Instalando Panel Dtunnel Mod..."
echo
sleep 3

# ==============================================
# INSTALACIÓN DE DEPENDENCIAS BÁSICAS
# ==============================================
echo "📦 Instalando dependencias del sistema..."
apt-get update -y
apt-get install -y wget curl zip npm cron unzip screen git

# Instalar PM2 globalmente
npm install pm2 -g 2>/dev/null

# ==============================================
# INSTALAR NODE.JS 20 (compatible Debian/Ubuntu)
# ==============================================
echo "🟢 Instalando Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - 
apt-get install -y nodejs

# ==============================================
# CLONAR REPOSITORIO Y CONFIGURAR
# ==============================================
echo "📥 Clonando repositorio..."
git clone https://github.com/johnnyrodriguezdk/paineldtunnel.git
cd /root/paineldtunnel

# Permisos para scripts auxiliares
chmod 777 pon poff menudt backmod
mv pon poff menudt backmod /bin

# Crear archivo .env
echo "PORT=$porta" > .env
echo "NODE_ENV=\"producción\"" >> .env
echo "DATABASE_URL=\"file:./database.db\"" >> .env

# Generar tokens de seguridad
token1=$(node -e "console.log(require('crypto').randomBytes(100).toString('base64'));")
token2=$(node -e "console.log(require('crypto').randomBytes(100).toString('base64'));")
token3=$(node -e "console.log(require('crypto').randomBytes(100).toString('base64'));")

echo "CSRF_SECRET=\"$token1\"" >> .env
echo "JWT_SECRET_KEY=\"$token2\"" >> .env
echo "JWT_SECRET_REFRESH=\"$token3\"" >> .env
echo "ENCRYPT_FILES=\"7223fd56-e21d-4191-8867-f3c67601122a\"" >> .env

# Instalar dependencias del proyecto
echo "📦 Instalando dependencias del panel..."
npm install

# Configurar base de datos
echo "🗄️ Configurando base de datos..."
npx prisma generate
npx prisma migrate deploy

# Iniciar panel
echo "🚀 Iniciando panel..."
npm run start

# ==============================================
# INTEGRACIÓN DTUNNEL SDK
# ==============================================
echo "🔄 Integrando DTunnel SDK..."

# Verificar que el archivo HTML existe
if [ -f /var/www/paineldtunnel/frontend/pages/application/index.html ]; then
    if ! grep -q "DTunnelSDK" /var/www/paineldtunnel/frontend/pages/application/index.html; then
        echo "📝 Agregando DTunnel SDK al panel..."
        
        # Backup
        cp /var/www/paineldtunnel/frontend/pages/application/index.html /var/www/paineldtunnel/frontend/pages/application/index.html.bak
        
        # Agregar script del SDK antes de </head>
        sed -i 's|</head>|<!-- DTunnel SDK -->\n<script src="https://cdn.jsdelivr.net/gh/DTunnel0/DTunnelSDK@main/sdk/dtunnel-sdk.js"></script>\n</head>|' /var/www/paineldtunnel/frontend/pages/application/index.html
        
        # Agregar código de integración antes de </body>
        sed -i 's|</body>|<script>\ndocument.addEventListener("DOMContentLoaded",function(){try{const e=new DTunnelSDK({strict:!1,autoRegisterNativeEvents:!0});window.dtunnelSDK=e,console.log("✅ DTunnel SDK listo!")}catch(e){console.error("❌ Error:",e)}});\nwindow.iniciarVPN=function(){window.dtunnelSDK&&window.dtunnelSDK.main.startVpn().catch(e=>alert("Error: "+e.message))};\nwindow.detenerVPN=function(){window.dtunnelSDK&&window.dtunnelSDK.main.stopVpn().catch(e=>alert("Error: "+e.message))};\n</script>\n</body>|' /var/www/paineldtunnel/frontend/pages/application/index.html
        
        echo "✅ DTunnel SDK integrado correctamente"
    else
        echo "✅ DTunnel SDK ya estaba presente"
    fi
else
    echo "⚠️ Archivo HTML no encontrado en /var/www/paineldtunnel/frontend/pages/application/index.html"
    echo "   La integración del SDK deberá hacerse manualmente."
fi

# ==============================================
# FINALIZACIÓN
# ==============================================
clear
echo
echo "=========================================="
echo "🎉 ¡PANEL DTUNNEL MOD INSTALADO CON ÉXITO!"
echo "=========================================="
echo "📁 Los archivos están en: /root/paineldtunnel"
echo
echo "📋 Comandos útiles:"
echo "   ▶️ ACTIVAR:   pon"
echo "   ⏹️ DESACTIVAR: poff"
echo "   📱 Menú:      menudt"
echo
echo -e "\033[1;36m🌐 ACCEDE A TU PANEL:\033[1;37m http://$IP\033[0m"
echo
echo "=========================================="
echo

# Limpiar y mostrar menú
rm /root/install.sh 2>/dev/null
pon > /dev/null 2>&1
sleep 2

echo -ne "\n\033[1;31mPULSA ENTER \033[1;33mpara continuar... \033[0m"; read
cat /dev/null > ~/.bash_history && history -c
rm -rf wget-log* > /dev/null 2>&1
rm install* > /dev/null 2>&1
sleep 2
menudt
