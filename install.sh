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
echo -e "${CYAN}██╗ ██╗ ██████╗ ██╗██████╗ ██╗██████╗ █████╗ ███╗ ██╗${NC}"
echo -e "${CYAN}██║ ██║██╔═══██╗██║██╔══██╗██║██╔══██╗██╔══██╗████╗ ██║${NC}"
echo -e "${CYAN}██║ ██║██║ ██║██║██████╔╝██║██████╔╝███████║██╔██╗ ██║${NC}"
echo -e "${CYAN}╚██╗ ██╔╝██║ ██║██║██╔═══╝ ██║██╔══██╗██╔══██║██║╚██╗██║${NC}"
echo -e "${CYAN} ╚████╔╝ ╚██████╔╝██║██║ ██║██║ ██║██║ ██║██║ ╚████║${NC}"
echo -e "${CYAN} ╚═══╝ ╚═════╝ ╚═╝╚═╝ ╚═╝╚══╝ ╚═╝╚═╝ ╚═╝╚═╝ ╚═══╝${NC}"
echo -e "${MAGENTA}###############################################################${NC}"
echo -e "${MAGENTA} https://voipiran.io ${NC}"
echo -e "${MAGENTA}###############################################################${NC}"
# بررسی دسترسی root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}لطفاً اسکریپت را با دسترسی root اجرا کنید.${NC}"
  exit 1
fi

# نصب پیش‌نیازها
echo -e "${YELLOW}🔧 نصب پیش‌نیازها...${NC}"
yum config-manager --set-enabled powertools
yum install -y git npm python3 python3-pip python3-virtualenv python3-mod_wsgi

# دریافت پروژه QPanel
echo -e "${YELLOW}📁 دریافت پروژه QPanel...${NC}"
rm -rf /var/www/html/qpanel
rm -rf /tmp/qpanel
git clone https://github.com/voipiran/VOIZ-QueuePanel /tmp/qpanel
cp -rf /tmp/qpanel /var/www/html/qpanel
cd /var/www/html/qpanel/

# نصب پکیج‌های Python
echo -e "${YELLOW}🐍 نصب پکیج‌های Python...${NC}"
pip3 install --user flask Flask-Babel --upgrade Werkzeug

# کلون و نصب Flask-Themes
echo -e "${YELLOW}📦 کلون و نصب Flask-Themes...${NC}"
rm -rf /tmp/flask-themes
git clone https://github.com/maxcountryman/flask-themes.git /tmp/flask-themes
pip3 install --user /tmp/flask-themes

# نصب ساده Node.js و وابستگی‌ها
echo -e "${YELLOW}🧩 نصب Node.js و وابستگی‌ها...${NC}"
yum install -y nodejs || { echo -e "${RED}خطا در نصب Node.js!${NC}"; exit 1; }
echo -e "${GREEN}نصب کامل شد: Node.js $(node --version), npm $(npm --version)${NC}"

# نصب وابستگی‌های Python و npm
echo -e "${YELLOW}📥 نصب وابستگی‌های Python و npm...${NC}"
pip3 install --user -r requirements.txt
npm install

# تنظیم فایل config.ini
echo -e "${YELLOW}⚙️ تنظیم فایل config.ini...${NC}"
cp samples/config.ini-dist config.ini
sed -i 's/^user *= *.*/user = phpconfig/' /var/www/html/qpanel/config.ini
sed -i 's/^password *= *.*/password = php[onfig/' /var/www/html/qpanel/config.ini

# افزودن تنظیمات AMI به Asterisk
echo -e "${YELLOW}🔐 افزودن تنظیمات AMI به Asterisk...${NC}"
cat <<EOL >> /etc/asterisk/manager_custom.conf
[phpconfig]
secret=php[onfig
deny=0.0.0.0/0.0.0.0
permit=127.0.0.1/255.255.255.0
read=all
write=all
EOL
service asterisk reload

# تنظیمات Apache و ترجمه‌ها
echo -e "${YELLOW}🧭 تنظیمات Apache و ترجمه‌ها...${NC}"
pybabel compile -d qpanel/translations

# ساخت سرویس systemd برای QPanel
echo -e "${YELLOW}🚀 ساخت سرویس systemd برای QPanel...${NC}"
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

echo -e "${GREEN}✅ نصب کامل شد! QPanel روی پورت 5000 و پروتکل HTTP در حال اجراست.${NC}"