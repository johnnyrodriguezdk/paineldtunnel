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

ubuntuV=$(lsb_release -r | awk '{print $2}' | cut -d. -f1)

[[ $(($ubuntuV < 20)) = 1 ]] && {
clear
echo "¡POR FAVOR, INSTALA EN UBUNTU 20.04 O 22.04! EL TUYO ES $ubuntuV"
echo
rm /root/install.sh
exit 0
}
[[ -e /root/paineldtunnel/src/index.ts ]] && {
  clear
  echo "EL PANEL YA ESTÁ INSTALADO. ¿DESEAS ELIMINARLO? (s/n)"
  read remo
  [[ $remo = @(s|S) ]] && {
  cd /root/paineldtunnel
  rm -r painelbackup > /dev/null
  mkdir painelbackup > /dev/null
  cp prisma/database.db painelbackup
  cp .env painelbackup
  zip -r painelbackup.zip painelbackup
  mv painelbackup.zip /root
  rm -r /root/paineldtunnel
  rm /root/install.sh
  echo "¡Eliminado con éxito!"
  # ==============================================
# INTEGRACIÓN DTUNNEL SDK
# ==============================================
echo "🔄 Verificando integración DTunnel SDK..."

# Verificar que el archivo HTML ya tenga el SDK
if ! grep -q "DTunnelSDK" /var/www/paineldtunnel/frontend/pages/application/index.html; then
    echo "📝 Agregando DTunnel SDK al panel..."
    
    # Backup del archivo original
    cp /var/www/paineldtunnel/frontend/pages/application/index.html /var/www/paineldtunnel/frontend/pages/application/index.html.bak
    
    # Agregar SDK antes de </head>
    sed -i 's|</head>|<!-- DTunnel SDK -->\n<script src="https://cdn.jsdelivr.net/gh/DTunnel0/DTunnelSDK@main/sdk/dtunnel-sdk.js"></script>\n</head>|' /var/www/paineldtunnel/frontend/pages/application/index.html
    
    # Agregar integración antes de </body>
    sed -i 's|</body>|<script>\ndocument.addEventListener("DOMContentLoaded",function(){try{const e=new DTunnelSDK({strict:!1,autoRegisterNativeEvents:!0});window.dtunnelSDK=e,console.log("✅ DTunnel SDK listo!")}catch(e){console.error("❌ Error:",e)}});\nwindow.iniciarVPN=function(){window.dtunnelSDK&&window.dtunnelSDK.main.startVpn().catch(e=>alert("Error: "+e.message))};\nwindow.detenerVPN=function(){window.dtunnelSDK&&window.dtunnelSDK.main.stopVpn().catch(e=>alert("Error: "+e.message))};\n</script>\n</body>|' /var/www/paineldtunnel/frontend/pages/application/index.html
    
    echo "✅ DTunnel SDK integrado correctamente"
else
    echo "✅ DTunnel SDK ya está presente"
fi
  exit 0
  }
  exit 0
}
clear
echo "¿QUÉ PUERTO DESEAS ACTIVAR?"
read porta
echo
echo "Instalando Panel Dtunnel Mod..."
echo
sleep 3
#========================
sudo apt-get update -y
sudo apt-get update -y
sudo apt-get install wget -y
sudo apt-get install curl -y
sudo apt-get install zip -y
sudo apt-get install npm -y /dev/null
npm install pm2 -g /dev/null
sudo apt-get install cron -y
sudo apt-get install unzip -y
sudo apt-get install screen -y
sudo apt-get install git -y
curl -s -L https://raw.githubusercontent.com/carlos-ayala/paineldtunnel/main/setup_20.x | bash
sudo apt-get install nodejs -y
#=========================
git clone https://github.com/johnnyrodriguezdk/paineldtunnel.git
cd /root/paineldtunnel 
chmod 777 pon poff menudt backmod
mv pon poff menudt backmod /bin
echo "PORT=$porta" > .env
echo "NODE_ENV=\"producción\"" >> .env
echo "DATABASE_URL=\"file:./database.db\"" >> .env
token1=$(node -e "console.log(require('crypto').randomBytes(100).toString('base64'));")
token2=$(node -e "console.log(require('crypto').randomBytes(100).toString('base64'));")
token3=$(node -e "console.log(require('crypto').randomBytes(100).toString('base64'));")
echo "CSRF_SECRET=\"$token1\"" >> .env
echo "JWT_SECRET_KEY=\"$token2\"" >> .env
echo "JWT_SECRET_REFRESH=\"$token3\"" >> .env
echo "ENCRYPT_FILES=\"7223fd56-e21d-4191-8867-f3c67601122a\"" >> .env
npm install
npx prisma generate
npx prisma migrate deploy
npm run start
#=========================
clear
echo
echo
echo "¡PANEL DTUNNEL MOD INSTALADO CON ÉXITO!"
echo "Los Archivos Quedan En La Carpeta /root/paineldtunnel"
echo
echo "Comando para ACTIVAR: pon"
echo "Comando para DESACTIVAR: poff"
echo
echo -e "\033[1;36mEscribe el comando: \033[1;37mmenudt \033[1;32m(Para acceder al Menú del Panel) \033[0m"
echo
rm /root/install.sh
pon
echo -e "\033[1;36mTU PANEL:\033[1;37m http://$IP\033[0m"
echo
echo -ne "\n\033[1;31mPULSA ENTER \033[1;33mPara Regresar \033[1;32mAl Prompt! \033[0m"; read
cat /dev/null > ~/.bash_history && history -c
rm -rf wget-log* > /dev/null 2>&1
rm install* > /dev/null 2>&1
sleep 3
menudt
