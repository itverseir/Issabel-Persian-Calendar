#!/bin/bash
# ==============================================================================
# Issabel PBX - Emergency 500 Rescue & Recovery Tool
# اسکریپت اضطراری رفع خطای ۵۰۰ و احیای کامل ایزابل ۴ و ۵
# Developed by: Amir Safari - ITVERSE.IR
# Copyright (c) 2024-2026 Amir Safari - ITVERSE.IR. All rights reserved.
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "=================================================================="
echo "    Issabel PBX - Emergency Recovery & Diagnostics Tool          "
echo "    ابزار اضطراری احیا و رفع خطای ۵۰۰ ایزابل                      "
echo "    توسعه‌دهنده: امیر صفری | Amir Safari - ITVERSE.IR            "
echo "=================================================================="
echo -e "${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] لطفاً این اسکریپت را با دسترسی root اجرا کنید.${NC}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_ROOT="/var/www/html"
PRISTINE_DIR="$SCRIPT_DIR/modules/persian_calendar/pristine_originals"

echo -e "${BLUE}1. در حال بررسی سلامت و بازگردانی فایل‌های سیستمی ...${NC}"

restore_file() {
    local target="$1"
    local pristine_name="$2"
    local min_size="$3"
    local pristine_path="$PRISTINE_DIR/$pristine_name"

    if [ ! -f "$target" ]; then
        if [ -f "$pristine_path" ]; then
            cp -f "$pristine_path" "$target"
            echo -e "${GREEN}  ✔ فایل مفقود $(basename "$target") از نسخه اورجینال بازگردانده شد.${NC}"
        fi
        return
    fi

    # Check syntax and file size
    local current_size=$(stat -c%s "$target" 2>/dev/null || echo 0)
    local is_corrupt=0

    if [ "$current_size" -lt "$min_size" ]; then
        is_corrupt=1
    fi

    if ! php -l "$target" >/dev/null 2>&1; then
        is_corrupt=1
    fi

    # Check for legacy broken injections
    if grep -q "unexpected identifier" "$target" 2>/dev/null || grep -q 'style="margin-left' "$target" 2>/dev/null; then
        is_corrupt=1
    fi

    if [ "$is_corrupt" -eq 1 ]; then
        echo -e "${YELLOW}  ⚠ فایل $(basename "$target") دچار خطا یا آسیب است. در حال بازیابی...${NC}"
        
        # 1. Try to find a healthy backup
        local restored=0
        for bak in $(ls -tr "${target}".bak_* 2>/dev/null); do
            local bsize=$(stat -c%s "$bak" 2>/dev/null || echo 0)
            if [ "$bsize" -ge "$min_size" ] && php -l "$bak" >/dev/null 2>&1; then
                cp -f "$bak" "$target"
                echo -e "${GREEN}  ✔ فایل $(basename "$target") از پشتیبان سالم $(basename "$bak") بازیابی شد.${NC}"
                restored=1
                break
            fi
        done

        # 2. If no healthy backup, use pristine original
        if [ "$restored" -eq 0 ] && [ -f "$pristine_path" ]; then
            cp -f "$pristine_path" "$target"
            echo -e "${GREEN}  ✔ فایل $(basename "$target") با موفقیت از نسخه ۱۰۰٪ اورجینال بازگردانده شد.${NC}"
        fi
    else
        echo -e "${GREEN}  ✔ فایل $(basename "$target") سالم است ($current_size بایت).${NC}"
    fi
}

restore_file "$WEB_ROOT/admin/views/header.php" "admin_views_header.php" 1000
restore_file "$WEB_ROOT/admin/config.php" "admin_config.php" 5000
restore_file "$WEB_ROOT/admin/modules/timeconditions/functions.inc.php" "tc_functions.inc.php" 10000
restore_file "$WEB_ROOT/admin/modules/timeconditions/page.timegroups.php" "tc_page.timegroups.php" 500
restore_file "$WEB_ROOT/libs/misc.lib.php" "framework_misc.lib.php" 5000
restore_file "$WEB_ROOT/index.php" "framework_index.php" 2000

echo -e "\n${BLUE}2. تنظیم مالکیت و دسترسی‌های وب‌سرور ...${NC}"
WEB_USER="asterisk"
if ! id "$WEB_USER" >/dev/null 2>&1; then
    WEB_USER="apache"
fi
chown -R "$WEB_USER:$WEB_USER" "$WEB_ROOT/admin" "$WEB_ROOT/modules" "$WEB_ROOT/themes" "$WEB_ROOT/libs" 2>/dev/null || true
chmod -R 755 "$WEB_ROOT/admin" "$WEB_ROOT/modules" "$WEB_ROOT/themes" "$WEB_ROOT/libs" 2>/dev/null || true
find "$WEB_ROOT" -maxdepth 2 -type f -name "*.php" -exec chmod 644 {} + 2>/dev/null || true

echo -e "\n${BLUE}3. پاکسازی کش قالب‌ها (Smarty Template Cache) ...${NC}"
rm -rf "$WEB_ROOT/var/templates_c"/* 2>/dev/null || true

echo -e "\n${BLUE}4. راه‌اندازی مجدد سرویس‌های وب (PHP-FPM و Apache) ...${NC}"
systemctl restart php-fpm 2>/dev/null || systemctl restart rh-php74-php-fpm 2>/dev/null || true
systemctl restart httpd 2>/dev/null || systemctl reload httpd 2>/dev/null || true

echo -e "\n${BLUE}5. آزمایش پاسخ‌دهی وب‌سرور ...${NC}"
HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" https://127.0.0.1/ 2>/dev/null || curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/ 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo -e "${GREEN}${BOLD}=================================================================="
    echo -e "  🎉 موفقیت‌آمیز: وب‌سرور ایزابل با کد $HTTP_CODE بدون خطا در دسترس است!"
    echo -e "==================================================================${NC}"
else
    echo -e "${YELLOW}  کد پاسخ وب‌سرور: $HTTP_CODE${NC}"
    echo -e "\n${YELLOW}در حال خواندن آخرین خطاهای ثبت شده در لاگ سرور:${NC}"
    for logfile in /var/log/php-fpm/www-error.log /var/log/php-fpm/error.log /var/log/httpd/error_log /var/log/httpd/ssl_error_log; do
        if [ -f "$logfile" ] && [ -s "$logfile" ]; then
            echo -e "${CYAN}--- [ $logfile ] ---${NC}"
            tail -n 15 "$logfile"
        fi
    done
fi
