# Issabel PBX - Persian Calendar & Shamsi DatePicker Module
### ماژول جامع تقویم و تاریخ شمسی برای سیستم تلفنی ایزابل

> **توسعه‌دهنده و مالکیت مادی و معنوی:** [امیر صفری (Amir Safari)](https://itverse.ir) - [ITVERSE.IR](https://itverse.ir)  
> **حق کپی‌رایت:** Copyright © 2024-2026 Amir Safari - ITVERSE.IR. All rights reserved.  
> **زبان‌ها / Languages:** [راهنمای فارسی](#راهنمای-فارسی-fa) | [English Documentation](#english-documentation-en)

---

<a name="راهنمای-فارسی-fa"></a>
## 🇮🇷 راهنمای فارسی

ماژول تقویم و تاریخ شمسی ایزابل، یک راهکار پایدار، ماژولار و سطح سازمانی است که امکانات کامل **تقویم خورشیدی (جلالی / هجری شمسی)** را بدون هیچ‌گونه دستکاری مخرب در ساختار دیتابیس استریسک، به سیستم تلفنی ایزابل (Issabel 4 و نسخه‌های جدیدتر) اضافه می‌کند.

### 🌟 قابلیت‌های کلیدی

1. **دیت‌پیکر شمسی زیبا، تعاملی و راست‌چین (RTL):**
   - جایگزینی اتوماتیک در تمام فرم‌های فیلتر تاریخ (گزارش مکالمات CDR Report، فایل‌های ضبط مکالمات و مانیتورینگ، گزارش صف‌ها، لاگ‌های سیستم و ...).
   - انتخاب سال، ماه و روز کاملاً فارسی همراه با دکمه‌های اقدام سریع «امروز» و «پاک کردن».

2. **تبدیل خودکار تاریخ‌ها در کلیه جداول و گزارشات:**
   - تبدیل تمامی زمان‌ها در ستون‌های گزارشات به تاریخ شمسی.
   - نمایش تاریخ و زمان اصلی میلادی در هنگام نگه داشتن ماوس روی تاریخ (Tooltip).
   - سازگاری ۱۰۰٪ با بازخوانی‌های زنده، صفحه‌بندی (Pagination) و فیلترهای AJAX.

3. **ساعت و تقویم زنده در نوار بالای ایزابل:**
   - نمایش تاریخ روز جاری به همراه روز هفته (مثلاً: `سه‌شنبه، ۲۴ مهر ۱۴۰۵`) و ساعت زنده در هدر پنل.

4. **هوک هوشمند کوئری‌های SQL (عدم دستکاری دیتابیس استریسک):**
   - رهگیری خودکار درخواست‌های فیلتر تاریخ و تبدیل معادل شمسی به میلادی قبل از اجرای کوئری در دیتابیس `asteriskcdrdb`.
   - عدم تداخل با شماره‌های داخلی (مانند داخلی‌های 1403، 1404 و ...).

5. **کنترل پنل تحت وب اختصاصی در منوی سیستم:**
   - مسیر منو: **System -> Persian Calendar (تاریخ شمسی)**.
   - امکان روشن/خاموش کردن کل ماژول با یک کلیک.
   - انتخاب فرمت نمایش ارقام: فارسی (۱۴۰۳/۰۸/۱۵) یا انگلیسی (1403/08/15).
   - انتخاب جداکننده تاریخ (`YYYY/MM/DD` یا `YYYY-MM-DD`).
   - ابزار تبدیل زنده تاریخ شمسی به میلادی و برعکس.
   - ابزار عیب‌یابی و بازسازی مجدد هوک‌ها.

6. **پشتیبانی کامل در Time Groups و Time Conditions:**
   - نمایش روزهای هفته منطبق بر تقویم کاری ایران (**شنبه تا جمعه**).
   - امکان انتخاب ماه‌های شمسی (**فروردین تا اسفند**) در کنار ماه‌های میلادی.
   - کامپایل خودکار به قوانین استاندارد دایل‌پلن استریسک (`GotoIfTime`) بدون نیاز به اسکریپت‌های سنگین AGI.

---

### 🚀 نحوه نصب سریع

تنها با اجرای دستورات زیر در ترمینال سرور ایزابل:

```bash
cd /tmp
# یا هر مسیری که فایل‌های ماژول را در آن قرار داده‌اید
cd PersianIssabel
chmod +x install.sh uninstall.sh
./install.sh
```

**اسکریپت نصب به صورت خودکار موارد زیر را انجام می‌دهد:**
- پشتیبان‌گیری خودکار از فایل‌های سیستم قبل از هر تغییر (`.bak`)
- انتقال فایل‌های ماژول به مسیر `/var/www/html/modules/persian_calendar`
- ثبت در دیتابیس منوی ایزابل (`menu.db`) و تنظیم مجوزهای دسترسی (`acl.db`)
- تزریق هوک بک‌اند در `/var/www/html/index.php`
- افزودن استایل‌ها و اسکریپت‌ها به قالب‌های فعال (`tenant`, `elastixneo`)
- تنظیم مالکیت فایل‌ها برای کاربر `asterisk:asterisk` و پاکسازی کش Smarty

---

### 🔄 نحوه حذف ماژول (Uninstall)

جهت حذف کامل ماژول و بازگردانی کلیه فایل‌های سرور به حالت اولیه:

```bash
./uninstall.sh
```

---

<a name="english-documentation-en"></a>
## 🇬🇧 English Documentation

A comprehensive, production-grade Persian (Solar Hijri / Jalali) localization module for **Issabel PBX** (Issabel 4 and newer Asterisk/FreePBX-based distributions).

### 🌟 Key Features

1. **Interactive Persian DatePicker:**
   - Automatically enhances and replaces Gregorian datepickers across all Issabel modules (CDR Reports, Call Recordings / Monitoring, Queue Logs, Audit Logs, etc.).
   - Full RTL support, Persian month names (فروردین to اسفند), weekday names, year selector, and quick "Today" / "Clear" actions.

2. **Dynamic Table & Grid Date Conversion:**
   - Automatically translates timestamps in CDR and report tables to Persian dates.
   - Preserves original Gregorian timestamp in mouse hover tooltip (`title="میلادی: ..."`).
   - Seamlessly handles AJAX pagination, table sorting, and dynamic live reloads.

3. **Live Persian System Clock:**
   - Displays real-time Shamsi date and current time in the top header navigation of Issabel PBX.

4. **Transparent SQL Query Translation (Backend Interceptor):**
   - Automatically intercepts request filters (`$_GET`, `$_POST`, `$_REQUEST`) containing Jalali dates and converts them to Gregorian before database queries execute in `asteriskcdrdb`.
   - Ensures Asterisk CDR queries return accurate records without modifying Asterisk's internal schema or corrupting database timestamps.
   - Protected with strict regex to avoid modifying extension numbers (e.g. extension `1403` remains untouched).

5. **Integrated Web Management GUI:**
   - Located in the Issabel Admin GUI under **System -> Persian Calendar**.
   - One-click module toggle (Enable/Disable).
   - Switch between Persian digits (۱۲۳) and Latin digits (123).
   - Date format customization (`YYYY/MM/DD` or `YYYY-MM-DD`).
   - Built-in Live Jalali <-> Gregorian conversion utility.
   - One-click diagnostic and hook repair tool.

6. **Time Groups & Time Conditions Persian Integration:**
   - Visual and logical Persian calendar support in FreePBX/Issabel Time Groups.
   - Weekdays aligned with Iran workweek: **Saturday to Friday (شنبه تا جمعه)**.
   - Full support for Persian months (**فروردین تا اسفند**) with dedicated optgroups alongside Gregorian months.
   - Automatic compilation into native Asterisk `GotoIfTime` dialplan rules spanning multi-month boundaries without requiring external AGI scripts.
   - Live Shamsi date and time indicator displayed in the Time Groups header.

---

### 🚀 Easy Installation

Installation takes just one command:

```bash
cd /path/to/PersianIssabel
chmod +x install.sh uninstall.sh
sudo ./install.sh
```

---

### 🔄 Uninstallation

To cleanly remove the module and restore original system files:

```bash
sudo ./uninstall.sh
```

---

### 🧪 Unit Testing

You can run the unit test suite on the server using PHP CLI:

```bash
php test_dates.php
```

---

## 📜 Copyright & License

- **Developer / Intellectual Property:** [Amir Safari](https://itverse.ir) - [ITVERSE.IR](https://itverse.ir)
- **Copyright:** Copyright © 2024-2026 Amir Safari - ITVERSE.IR. All rights reserved.
- **License:** [MIT License](LICENSE) - Free for personal and commercial PBX deployments with proper attribution.
