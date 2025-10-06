bash
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
clear
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
  echo -e "${RED}لطفاً اسکریپت را با دسترسی root اجرا کنید.${NC}"
  exit 1
fi
# نصب پیش‌نیازها
echo -e "${YELLOW}🔧 نصب پیش‌نیازها...${NC}"
yum config-manager --set-enabled powertools
yum install -y git npm python3 python3-pip python3-virtualenv python3-mod_wsgi || { echo -e "${RED}خطا در نصب پیش‌نیازها!${NC}"; exit 1; }
pip3 install Babel || { echo -e "${RED}خطا در نصب پکیج Babel!${NC}"; exit 1; }
cd /var/www/html/qpanel/ || { echo -e "${RED}خطا در تغییر دایرکتوری به qpanel!${NC}"; exit 1; }
# نصب پکیج‌های Python
echo -e "${YELLOW}🐍 نصب پکیج‌های Python...${NC}"
pip3 install --user flask Flask-Babel --upgrade Werkzeug || { echo -e "${RED}خطا در نصب پکیج‌های Python!${NC}"; exit 1; }
# کلون و نصب Flask-Themes
echo -e "${YELLOW}📦 کلون و نصب Flask-Themes...${NC}"
rm -rf /tmp/flask-themes
git clone https://github.com/maxcountryman/flask-themes.git /tmp/flask-themes || { echo -e "${RED}خطا در کلون کردن Flask-Themes!${NC}"; exit 1; }
pip3 install --user /tmp/flask-themes || { echo -e "${RED}خطا در نصب Flask-Themes!${NC}"; exit 1; }
# نصب ساده Node.js و وابستگی‌ها
echo -e "${YELLOW}🧩 نصب Node.js و وابستگی‌ها...${NC}"
yum install -y nodejs --skip-broken || { echo -e "${RED}خطا در نصب Node.js!${NC}"; exit 1; }
echo -e "${GREEN}نصب کامل شد: Node.js $(node --version), npm $(npm --version)${NC}"
# نصب وابستگی‌های Python و npm
echo -e "${YELLOW}📥 نصب وابستگی‌های Python و npm...${NC}"
pip3 install --user -r /var/www/html/qpanel/requirements.txt || { echo -e "${RED}خطا در نصب requirements.txt!${NC}"; exit 1; }
npm install || { echo -e "${RED}خطا در نصب وابستگی‌های npm!${NC}"; exit 1; }
# تنظیم فایل config.ini
echo -e "${YELLOW}⚙️ تنظیم فایل config.ini...${NC}"
cp /var/www/html/qpanel/samples/config.ini-dist config.ini || { echo -e "${RED}خطا در کپی config.ini!${NC}"; exit 1; }
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
service asterisk reload || { echo -e "${RED}خطا در ری‌لود Asterisk!${NC}"; exit 1; }
# تنظیمات Apache و ترجمه‌ها
echo -e "${YELLOW}🧭 تنظیمات Apache و ترجمه‌ها...${NC}"
cp samples/configs/site-apache2-wsgi.conf /etc/httpd/conf.d/qpanel.conf
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
systemctl start qpanel || { echo -e "${RED}خطا در شروع سرویس qpanel!${NC}"; exit 1; }
systemctl enable qpanel || { echo -e "${RED}خطا در فعال‌سازی سرویس qpanel!${NC}"; exit 1; }
echo -e "${GREEN}✅ نصب کامل شد! QPanel روی پورت 5000 و پروتکل HTTP در حال اجراست.${NC}"
