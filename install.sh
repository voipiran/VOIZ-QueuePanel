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
LOG_FILE="/var/log/qpanel-install.log"

# ایجاد یا پاک کردن فایل لاگ
> "$LOG_FILE" || { echo -e "${RED}خطا در ایجاد فایل لاگ $LOG_FILE!${NC}"; exit 1; }
echo "QPanel Installation Log - $(date)" >> "$LOG_FILE"

# نمایش لوگو
echo -e "${MAGENTA}###############################################################${NC}"
echo -e "${CYAN}██╗ ██╗ ██████╗ ██╗██████╗ ██╗██████╗ █████╗ ███╗ ██╗${NC}"
echo -e "${CYAN}██║ ██║██╔═══██╗██║██╔══██╗██║██╔══██╗██╔══██╗████╗ ██║${NC}"
echo -e "${CYAN}██║ ██║██║ ██║██║██████╔╝██║██████╔╝███████║██╔██╗ ██║${NC}"
echo -e "${CYAN}╚██╗ ██╔╝██║ ██║██║██╔═══╝ ██║██╔══██╗██╔══██║██║╚██╗██║${NC}"
echo -e "${CYAN} ╚████╔╝ ╚██████╔╝██║██║ ██║██║ ██║██║ ██║██║ ╚████║${NC}"
echo -e "${CYAN} ╚═══╝ ╚═════╝ ╚═╝╚═╝ ╚═╝╚══╝ ╚═╝╚═╝ ╚═╝╚═╝ ╚═══╝${NC}"
echo -e "${MAGENTA}###############################################################${NC}"
echo -e "${MAGENTA} https://voipiran.io ${NC}"
echo -e "${MAGENTA}###############################################################${NC}" | tee -a "$LOG_FILE"

# بررسی دسترسی root
echo -e "${YELLOW}🔍 بررسی دسترسی root...${NC}" | tee -a "$LOG_FILE"
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}لطفاً اسکریپت را با دسترسی root اجرا کنید.${NC}" | tee -a "$LOG_FILE"
  exit 1
fi

# بررسی وجود yum
echo -e "${YELLOW}🔍 بررسی وجود yum...${NC}" | tee -a "$LOG_FILE"
if ! command -v yum >/dev/null 2>&1; then
  echo -e "${RED}دستور yum یافت نشد!${NC}" | tee -a "$LOG_FILE"
  exit 1
fi

# تنظیم مخزن powertools یا crb
echo -e "${YELLOW}🔧 تنظیم مخزن powertools...${NC}" | tee -a "$LOG_FILE"
if ! yum config-manager --set-enabled powertools >/dev/null 2>>"$LOG_FILE"; then
  echo -e "${YELLOW}تلاش برای تنظیم مخزن crb...${NC}" | tee -a "$LOG_FILE"
  yum config-manager --set-enabled crb >/dev/null 2>>"$LOG_FILE" || { echo -e "${RED}خطا در تنظیم مخزن powertools یا crb!${NC}" | tee -a "$LOG_FILE"; exit 1; }
fi

# نصب پیش‌نیازها
echo -e "${YELLOW}🔧 نصب پیش‌نیازها...${NC}" | tee -a "$LOG_FILE"
yum install -y epel-release >/dev/null 2>>"$LOG_FILE" || { echo -e "${RED}خطا در نصب epel-release!${NC}" | tee -a "$LOG_FILE"; exit 1; }
yum install -y git npm python3 python3-pip python3-virtualenv python3-mod_wsgi python3-babel >/dev/null 2>>"$LOG_FILE" || { echo -e "${RED}خطا در نصب پیش‌نیازها!${NC}" | tee -a "$LOG_FILE"; exit 1; }
echo -e "${GREEN}پیش‌نیازها نصب شدند.${NC}" | tee -a "$LOG_FILE"

# بررسی وجود دایرکتوری qpanel
echo -e "${YELLOW}📁 بررسی دایرکتوری qpanel...${NC}" | tee -a "$LOG_FILE"
if [ ! -d /var/www/html/qpanel ]; then
  echo -e "${RED}دایرکتوری /var/www/html/qpanel وجود ندارد!${NC}" | tee -a "$LOG_FILE"
  exit 1
fi
cd /var/www/html/qpanel/ 2>>"$LOG_FILE" || { echo -e "${RED}خطا در تغییر دایرکتوری به qpanel!${NC}" | tee -a "$LOG_FILE"; exit 1; }
echo -e "${GREEN}تغییر دایرکتوری به qpanel انجام شد.${NC}" | tee -a "$LOG_FILE"

# نصب پکیج‌های Python
echo -e "${YELLOW}🐍 نصب پکیج‌های Python...${NC}" | tee -a "$LOG_FILE"
pip3 install --user flask Flask-Babel Werkzeug --upgrade >/dev/null 2>>"$LOG_FILE" || { echo -e "${RED}خطا در نصب پکیج‌های Python!${NC}" | tee -a "$LOG_FILE"; exit 1; }
echo -e "${GREEN}پکیج‌های Python نصب شدند.${NC}" | tee -a "$LOG_FILE"

# کلون و نصب Flask-Themes
echo -e "${YELLOW}📦 کلون و نصب Flask-Themes...${NC}" | tee -a "$LOG_FILE"
rm -rf /tmp/flask-themes 2>>"$LOG_FILE"
git clone https://github.com/maxcountryman/flask-themes.git /tmp/flask-themes >/dev/null 2>>"$LOG_FILE" || { echo -e "${RED}خطا در کلون کردن Flask-Themes!${NC}" | tee -a "$LOG_FILE"; exit 1; }
pip3 install --user /tmp/flask-themes >/dev/null 2>>"$LOG_FILE" || { echo -e "${RED}خطا در نصب Flask-Themes!${NC}" | tee -a "$LOG_FILE"; exit 1; }
echo -e "${GREEN}Flask-Themes نصب شد.${NC}" | tee -a "$LOG_FILE"

# نصب وابستگی‌های Python و npm
echo -e "${YELLOW}📥 نصب وابستگی‌های Python و npm...${NC}" | tee -a "$LOG_FILE"
if [ -f /var/www/html/qpanel/requirements.txt ]; then
  pip3 install -r /var/www/html/qpanel/requirements.txt >/dev/null 2>>"$LOG_FILE" || { echo -e "${RED}خطا در نصب requirements.txt!${NC}" | tee -a "$LOG_FILE"; exit 1; }
else
  echo -e "${RED}فایل requirements.txt یافت نشد!${NC}" | tee -a "$LOG_FILE"
  exit 1
fi
npm install >/dev/null 2>>"$LOG_FILE" || { echo -e "${RED}خطا در نصب وابستگی‌های npm!${NC}" | tee -a "$LOG_FILE"; exit 1; }
echo -e "${GREEN}وابستگی‌های Python و npm نصب شدند.${NC}" | tee -a "$LOG_FILE"

# تنظیم فایل config.ini
echo -e "${YELLOW}⚙️ تنظیم فایل config.ini...${NC}" | tee -a "$LOG_FILE"
if [ -f /var/www/html/qpanel/samples/config.ini-dist ]; then
  cp /var/www/html/qpanel/samples/config.ini-dist config.ini 2>>"$LOG_FILE" || { echo -e "${RED}خطا در کپی config.ini!${NC}" | tee -a "$LOG_FILE"; exit 1; }
else
  echo -e "${RED}فایل samples/config.ini-dist یافت نشد!${NC}" | tee -a "$LOG_FILE"
  exit 1
fi
sed -i 's/^user *= *.*/user = phpconfig/' /var/www/html/qpanel/config.ini 2>>"$LOG_FILE"
sed -i 's/^password *= *.*/password = php[onfig/' /var/www/html/qpanel/config.ini 2>>"$LOG_FILE"
echo -e "${GREEN}فایل config.ini تنظیم شد.${NC}" | tee -a "$LOG_FILE"

# افزودن تنظیمات AMI به Asterisk
echo -e "${YELLOW}🔐 افزودن تنظیمات AMI به Asterisk...${NC}" | tee -a "$LOG_FILE"
cat <<EOL >> /etc/asterisk/manager_custom.conf
[phpconfig]
secret=php[onfig
deny=0.0.0.0/0.0.0.0
permit=127.0.0.1/255.255.255.0
read=all
write=all
EOL
service asterisk reload >/dev/null 2>>"$LOG_FILE" || { echo -e "${RED}خطا در ری‌لود Asterisk!${NC}" | tee -a "$LOG_FILE"; exit 1; }
echo -e "${GREEN}تنظیمات AMI به Asterisk اضافه شد.${NC}" | tee -a "$LOG_FILE"

# تنظیمات Apache و ترجمه‌ها
echo -e "${YELLOW}🧭 تنظیمات Apache و ترجمه‌ها...${NC}" | tee -a "$LOG_FILE"
if [ -f samples/configs/site-apache2-wsgi.conf ]; then
  cp samples/configs/site-apache2-wsgi.conf /etc/httpd/conf.d/qpanel.conf 2>>"$LOG_FILE" || { echo -e "${RED}خطا در کپی فایل Apache config!${NC}" | tee -a "$LOG_FILE"; exit 1; }
else
  echo -e "${RED}فایل samples/configs/site-apache2-wsgi.conf یافت نشد!${NC}" | tee -a "$LOG_FILE"
  exit 1
fi
if command -v pybabel >/dev/null 2>&1; then
  pybabel compile -d qpanel/translations 2>>"$LOG_FILE" || { echo -e "${RED}خطا در کامپایل ترجمه‌ها با pybabel!${NC}" | tee -a "$LOG_FILE"; exit 1; }
else
  echo -e "${RED}دستور pybabel یافت نشد!${NC}" | tee -a "$LOG_FILE"
  exit 1
fi
echo -e "${GREEN}تنظیمات Apache و ترجمه‌ها انجام شد.${NC}" | tee -a "$LOG_FILE"

# ساخت سرویس systemd برای QPanel
echo -e "${YELLOW}🚀 ساخت سرویس systemd برای QPanel...${NC}" | tee -a "$LOG_FILE"
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
systemctl daemon-reexec >/dev/null 2>>"$LOG_FILE" || { echo -e "${RED}خطا در اجرای daemon-reexec!${NC}" | tee -a "$LOG_FILE"; exit 1; }
systemctl start qpanel >/dev/null 2>>"$LOG_FILE" || { echo -e "${RED}خطا در شروع سرویس qpanel!${NC}" | tee -a "$LOG_FILE"; exit 1; }
systemctl enable qpanel >/dev/null 2>>"$LOG_FILE" || { echo -e "${RED}خطا در فعال‌سازی سرویس qpanel!${NC}" | tee -a "$LOG_FILE"; exit 1; }
echo -e "${GREEN}سرویس qpanel راه‌اندازی شد.${NC}" | tee -a "$LOG_FILE"

echo -e "${GREEN}✅ نصب کامل شد! QPanel روی پورت 5000 و پروتکل HTTP در حال اجراست.${NC}" | tee -a "$LOG_FILE"