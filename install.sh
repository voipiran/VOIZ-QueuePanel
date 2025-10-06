bash
#!/bin/bash

# تعریف متغیرهای ثابت
LOG_FILE="/var/www/voiz-installation.log"
WWW_DIR="/var/www"

# بررسی دسترسی root
if [ "$EUID" -ne 0 ]; then
    echo "لطفاً اسکریپت را با دسترسی root اجرا کنید." >> "$LOG_FILE"
    exit 1
fi

# تابع برای نمایش پیام‌ها و ذخیره در لاگ
log_message() {
    echo -e "${YELLOW}$1${NC}"
    echo "$1" >> "$LOG_FILE"
}

# تابع برای بررسی خطاها
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}خطا: $1${NC}" >&2
        echo "خطا: $1" >> "$LOG_FILE"
        exit 1
    fi
}

# نمایش لوگو
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
log_message "شروع نصب QPanel..."

# نصب پیش‌نیازها
log_message "🔧 نصب پیش‌نیازها..."
yum config-manager --set-enabled powertools >/dev/null 2>&1
check_error "فعال‌سازی مخزن powertools با شکست مواجه شد."
yum install -y git npm python3 python3-pip python3-virtualenv python3-mod_wsgi >/dev/null 2>&1
check_error "نصب پیش‌نیازها با شکست مواجه شد."

# نصب صریح Babel برای pybabel
log_message "📦 نصب پکیج Babel..."
pip3 install --no-warn-script-location Babel >/dev/null 2>&1
check_error "نصب پکیج Babel با شکست مواجه شد."

# بررسی وجود pybabel
if ! command -v pybabel >/dev/null 2>&1; then
    log_message "⚠️ ابزار pybabel یافت نشد. تلاش برای نصب مجدد Babel..."
    pip3 install --no-warn-script-location --force-reinstall Babel >/dev/null 2>&1
    check_error "نصب مجدد Babel با شکست مواجه شد."
fi

# تغییر دایرکتوری به qpanel
cd "$WWW_DIR/html/qpanel" || check_error "تغییر دایرکتوری به qpanel با شکست مواجه شد."

# نصب پکیج‌های Python
log_message "🐍 نصب پکیج‌های Python..."
pip3 install --no-warn-script-location flask Flask-Babel Werkzeug --upgrade >/dev/null 2>&1
check_error "نصب پکیج‌های Python با شکست مواجه شد."

# کلون و نصب Flask-Themes
log_message "📦 کلون و نصب Flask-Themes..."
rm -rf /tmp/flask-themes >/dev/null 2>&1
git clone https://github.com/maxcountryman/flask-themes.git /tmp/flask-themes >/dev/null 2>&1
check_error "کلون کردن Flask-Themes با شکست مواجه شد."
pip3 install --no-warn-script-location /tmp/flask-themes >/dev/null 2>&1
check_error "نصب Flask-Themes با شکست مواجه شد."

# نصب ساده Node.js و وابستگی‌ها
log_message "🧩 نصب Node.js و وابستگی‌ها..."
yum install -y nodejs --skip-broken >/dev/null 2>&1
check_error "نصب Node.js با شکست مواجه شد."
log_message "نصب کامل شد: Node.js $(node --version), npm $(npm --version)"

# نصب وابستگی‌های Python و npm
log_message "📥 نصب وابستگی‌های Python و npm..."
pip3 install --no-warn-script-location -r "$WWW_DIR/html/qpanel/requirements.txt" >/dev/null 2>&1
check_error "نصب requirements.txt با شکست مواجه شد."
npm install >/dev/null 2>&1
check_error "نصب وابستگی‌های npm با شکست مواجه شد."

# تنظیم فایل config.ini
log_message "⚙️ تنظیم فایل config.ini..."
cp "$WWW_DIR/html/qpanel/samples/config.ini-dist" "$WWW_DIR/html/qpanel/config.ini" >/dev/null 2>&1
check_error "کپی config.ini با شکست مواجه شد."
sed -i 's/^user *= *.*/user = phpconfig/' "$WWW_DIR/html/qpanel/config.ini" >/dev/null 2>&1
check_error "تنظیم user در config.ini با شکست مواجه شد."
sed -i 's/^password *= *.*/password = php[onfig/' "$WWW_DIR/html/qpanel/config.ini" >/dev/null 2>&1
check_error "تنظیم password در config.ini با شکست مواجه شد."

# افزودن تنظیمات AMI به Asterisk
log_message "🔐 افزودن تنظیمات AMI به Asterisk..."
cat <<EOL >> /etc/asterisk/manager_custom.conf
[phpconfig]
secret=php[onfig
deny=0.0.0.0/0.0.0.0
permit=127.0.0.1/255.255.255.0
read=all
write=all
EOL
check_error "افزودن تنظیمات AMI به Asterisk با شکست مواجه شد."
systemctl reload asterisk >/dev/null 2>&1
check_error "ری‌لود سرویس Asterisk با شکست مواجه شد."

# تنظیمات Apache و ترجمه‌ها
log_message "🧭 تنظیمات Apache و ترجمه‌ها..."
pybabel compile -d qpanel/translations >/dev/null 2>&1
check_error "کامپایل ترجمه‌ها با شکست مواجه شد."

# ساخت سرویس systemd برای QPanel
log_message "🚀 ساخت سرویس systemd برای QPanel..."
cat <<EOL > /etc/systemd/system/qpanel.service
[Unit]
Description=QPanel VOIPIRAN
After=network.target
[Service]
User=root
WorkingDirectory=$WWW_DIR/html/qpanel
ExecStart=/usr/bin/python3 app.py
Restart=always
[Install]
WantedBy=multi-user.target
EOL
check_error "ایجاد فایل سرویس qpanel با شکست مواجه شد."
systemctl daemon-reload >/dev/null 2>&1
check_error "ری‌لود systemd با شکست مواجه شد."
systemctl start qpanel >/dev/null 2>&1
check_error "شروع سرویس qpanel با شکست مواجه شد."
systemctl enable qpanel >/dev/null 2>&1
check_error "فعال‌سازی سرویس qpanel با شکست مواجه شد."

# تنظیم پرمیشن‌ها
chmod -R 755 "$WWW_DIR/html/qpanel" >/dev/null 2>&1
check_error "تنظیم پرمیشن‌های qpanel با شکست مواجه شد."
chown -R asterisk:asterisk "$WWW_DIR/html/qpanel" >/dev/null 2>&1
check_error "تنظیم مالکیت qpanel با شکست مواجه شد."

# پاک‌سازی دایرکتوری موقت
rm -rf /tmp/flask-themes >/dev/null 2>&1
check_error "پاک‌سازی دایرکتوری موقت flask-themes با شکست مواجه شد."

log_message "✅ نصب کامل شد! QPanel روی پورت 5000 و پروتکل HTTP در حال اجراست."
