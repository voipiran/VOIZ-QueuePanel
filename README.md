&nbsp;
<p align="center">
  <a href="https://voipiran.io">
  </a>
</p>
<h3 align="center">The Dashboard for Queues/CallCenter in Asterisk and FreeSWITCH</h3>
<hr />



![Demo](samples/animation.gif)

##Install
```
curl -L -o /tmp/VOIZ-QueuePanel.zip https://github.com/voipiran/VOIZ-QueuePanel/archive/refs/heads/main.zip && \
unzip -o /tmp/VOIZ-QueuePanel.zip -d /tmp && \
mv /tmp/VOIZ-QueuePanel-main /var/www/html/qpanel && \
bash /var/www/html/qpanel/install.sh && \
rm /tmp/VOIZ-QueuePanel.zip
```


## Overview

Queue Panel یک پنل برای صف‌ها در سیستم‌های Asterisk و FreeSWITCH است؛ ابزاری قدرتمند و ساده برای مانیتورینگ زنده تماس‌ها:

خلاصه کلی تماس‌ها شامل: تماس‌های رهاشده، تماس‌های ورودی، زمان پاسخ‌گویی و زمان انتظار.

نمایش جزئیات هر صف به‌صورت جداگانه.

نمایش وضعیت اپراتورها (آزاد، مشغول یا در دسترس نبودن).

نمایش دلیل و مدت زمان مکث (Pause) اپراتورها.

نمایش درصد تماس‌های رهاشده.

امکان تغییر نام صف یا مخفی کردن آن در صورت نیاز.

نمایش لیست تماس‌گیرندگان هر صف همراه با اولویت و مدت انتظار.

امکان شنود (Spy)، پچ‌پچ (Whisper) و ورود به تماس (Barge) برای اپراتورهای صف.

نمایش سطح سرویس (Service Level) هر صف.

قطع تماس‌های ورودی.

دسترسی با احراز هویت.

پیکربندی ساده از طریق Asterisk Manager.

پشتیبانی از چند زبان: انگلیسی، اسپانیایی، آلمانی، روسی و پرتغالی.

نوشته‌شده با زبان Python.

طراحی واکنش‌گرا (Responsive).

متن‌باز با مجوز MIT.





