#!/bin/bash

clear
# Colorize output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[1;35m'
BOLD='\033[1m'
NC='\033[0m' # No color
echo -e "${MAGENTA}###############################################################${NC}"
echo -e "${CYAN}██╗   ██╗ ██████╗ ██╗██████╗ ██╗██████╗  █████╗ ███╗   ██╗${NC}"
echo -e "${CYAN}██║   ██║██╔═══██╗██║██╔══██╗██║██╔══██╗██╔══██╗████╗  ██║${NC}"
echo -e "${CYAN}██║   ██║██║   ██║██║██████╔╝██║██████╔╝███████║██╔██╗ ██║${NC}"
echo -e "${CYAN}╚██╗ ██╔╝██║   ██║██║██╔═══╝ ██║██╔══██╗██╔══██║██║╚██╗██║${NC}"
echo -e "${CYAN} ╚████╔╝ ╚██████╔╝██║██║     ██║██║  ██║██║  ██║██║ ╚████║${NC}"
echo -e "${CYAN}  ╚═══╝   ╚═════╝ ╚═╝╚═╝     ╚═╝╚══╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝${NC}"
echo -e "${MAGENTA}###############################################################${NC}"
echo -e "${MAGENTA}                    https://voipiran.io                    ${NC}"
echo -e "${MAGENTA}###############################################################${NC}"

# بررسی دسترسی root
if [ "$EUID" -ne 0 ]; then
  echo "لطفاً اسکریپت را با دسترسی root اجرا کنید."
  exit 1
fi

echo "🔧 نصب پیش‌نیازها..."
dnf config-manager --set-enabled powertools
dnf install -y git npm python3 python3-pip python3-virtualenv python3-mod_wsgi

echo "📁 دریافت پروژه QPanel..."
cd /var/www/html
git clone https://github.com/voipiran/VOIZ-QueuePanel qpanel
cd qpanel/

echo "🐍 نصب پکیج‌های Python..."
pip3 install flask Flask-Babel --upgrade Werkzeug
git clone https://github.com/maxcountryman/flask-themes.git /tmp/flask-themes
pip3 install /tmp/flask-themes

echo "🧩 نصب Node.js و وابستگی‌ها..."
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
dnf install -y nodejs
pip3 install --upgrade Flask-Themes
pip3 install -r /var/www/html/qpanel/requirements.txt
npm install

echo "⚙️ تنظیم فایل config.ini..."
cp samples/config.ini-dist config.ini
sed -i 's/^user *= *.*/user = phpconfig/' /var/www/html/qpanel/config.ini
sed -i 's/^password *= *.*/password = php[onfig/' /var/www/html/qpanel/config.ini

echo "🔐 افزودن تنظیمات AMI به Asterisk..."
cat <<EOL >> /etc/asterisk/manager_custom.conf

[phpconfig]
secret=php[onfig
deny=0.0.0.0/0.0.0.0
permit=127.0.0.1/255.255.255.0
read=all
write=all
EOL

service asterisk reload

echo "🧭 تنظیمات Apache و ترجمه‌ها..."
cp samples/configs/site-apache2-wsgi.conf /etc/httpd/conf.d/qpanel.conf
pybabel compile -d qpanel/translations

echo "🚀 ساخت سرویس systemd برای QPanel..."
cat <<EOL > /etc/systemd/system/qpanel.service
[Unit]
Description=QPanel VOIPIRAN
After=network.target

[Service]
User=root
WorkingDirectory=/var/www/html/qpanel
ExecStart=/usr/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reexec
systemctl start qpanel
systemctl enable qpanel

issabel-menumerge /var/www/html/qpanel/menu.xml


echo "✅ نصب کامل شد! QPanel روی پورت 5000 و پروتکل HTTP در حال اجراست."
