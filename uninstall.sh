#!/bin/bash
# ==============================================================================
# Issabel PBX - Persian Calendar Module Uninstaller
# اسکریپت حذف ماژول تقویم شمسی ایزابل
# Developed by: Amir Safari - ITVERSE.IR
# Copyright (c) 2024-2026 Amir Safari - ITVERSE.IR. All rights reserved.
# مالکیت مادی و معنوی: امیر صفری - ITVERSE.IR
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${YELLOW}${BOLD}"
echo "=================================================================="
echo "    حذف ماژول تقویم شمسی ایزابل (Uninstall Persian Calendar)    "
echo "    توسعه‌دهنده: امیر صفری | Amir Safari - ITVERSE.IR            "
echo "=================================================================="
echo -e "${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] لطفاً با دسترسی root اجرا کنید.${NC}"
    exit 1
fi

WEB_ROOT="/var/www/html"
if [ ! -d "$WEB_ROOT" ]; then
    if [ -d "/usr/share/issabel" ]; then
        WEB_ROOT="/usr/share/issabel"
    fi
fi

MODULE_DEST="$WEB_ROOT/modules/persian_calendar"
INDEX_FILE="$WEB_ROOT/index.php"
MENU_DB="/var/www/db/menu.db"
ACL_DB="/var/www/db/acl.db"

# 1. Clean index.php
echo -e "${BLUE}[1/5] پاکسازی هوک در $INDEX_FILE ...${NC}"
if [ -f "$INDEX_FILE" ]; then
    php -r '
        $file = $argv[1];
        $c = file_get_contents($file);
        $c = preg_replace("/\/\/ START ISSABEL PERSIAN CALENDAR HOOK.*?\/\/ END ISSABEL PERSIAN CALENDAR HOOK\n?/s", "", $c);
        file_put_contents($file, $c);
    ' "$INDEX_FILE"
    echo -e "${GREEN}  ✔ هوک بک‌اند حذف شد.${NC}"
fi

# 2. Clean Theme Templates and Popups
echo -e "${BLUE}[2/5] پاکسازی قالب‌های ایزابل و پاپ‌آپ‌ها ...${NC}"
THEME_FILES=(
    "$WEB_ROOT/themes/tenant/_common/index.tpl"
    "$WEB_ROOT/themes/tenant/_common/popup.tpl"
    "$WEB_ROOT/themes/farsi_rtl/_common/index.tpl"
    "$WEB_ROOT/themes/farsi_rtl/_common/popup.tpl"
    "$WEB_ROOT/themes/tenant/_common/_menu.tpl"
    "$WEB_ROOT/themes/farsi_rtl/_common/_menu.tpl"
    "$WEB_ROOT/themes/elastixneo/_common/index.tpl"
    "$WEB_ROOT/themes/elastixneo/_common/popup.tpl"
    "$WEB_ROOT/themes/default/_common/index.tpl"
    "$WEB_ROOT/themes/default/_common/popup.tpl"
    "$WEB_ROOT/modules/cdrreport/themes/default/cel.tpl"
)

for TPL in "${THEME_FILES[@]}"; do
    if [ -f "$TPL" ]; then
        php -r '
            $file = $argv[1];
            $c = file_get_contents($file);
            $c = preg_replace("/<!-- START ISSABEL PERSIAN CALENDAR -->.*?<!-- END ISSABEL PERSIAN CALENDAR -->\n?/s", "", $c);
            file_put_contents($file, $c);
        ' "$TPL"
        echo -e "${GREEN}  ✔ قالب $(basename $(dirname $(dirname "$TPL")))/$(basename "$TPL") پاکسازی شد.${NC}"
    fi
done

# Clean misc.lib.php
MISC_LIB="$WEB_ROOT/libs/misc.lib.php"
if [ -f "$MISC_LIB" ]; then
    php -r '
        $file = $argv[1];
        $c = file_get_contents($file);
        $c = preg_replace("/\/\/ translateDate - Persian support.*?\n    }/s", "", $c);
        file_put_contents($file, $c);
    ' "$MISC_LIB"
fi

# Clean Time Groups and Time Conditions
TC_FUNCS="$WEB_ROOT/admin/modules/timeconditions/functions.inc.php"
TC_PAGE="$WEB_ROOT/admin/modules/timeconditions/page.timegroups.php"

if [ -f "$TC_FUNCS" ]; then
    LATEST_BAK=$(ls -t "${TC_FUNCS}".bak_* 2>/dev/null | head -n 1)
    if [ -n "$LATEST_BAK" ] && [ -f "$LATEST_BAK" ]; then
        cp "$LATEST_BAK" "$TC_FUNCS"
        echo -e "${GREEN}  ✔ فایل functions.inc.php از پشتیبان بازیابی شد.${NC}"
    fi
fi

if [ -f "$TC_PAGE" ]; then
    LATEST_BAK=$(ls -t "${TC_PAGE}".bak_* 2>/dev/null | head -n 1)
    if [ -n "$LATEST_BAK" ] && [ -f "$LATEST_BAK" ]; then
        cp "$LATEST_BAK" "$TC_PAGE"
        echo -e "${GREEN}  ✔ فایل page.timegroups.php از پشتیبان بازیابی شد.${NC}"
    fi
fi

# 3. Clean Databases
echo -e "${BLUE}[3/5] حذف ثبت منو و دسترسی‌ها از دیتابیس ...${NC}"

execute_sqlite() {
    local db_file="$1"
    local sql_query="$2"
    if command -v sqlite3 >/dev/null 2>&1; then
        sqlite3 "$db_file" "$sql_query"
    elif command -v php >/dev/null 2>&1; then
        php -r "
            \$db = new SQLite3('$db_file');
            \$db->exec(\"$sql_query\");
        "
    fi
}

if [ -f "$MENU_DB" ]; then
    execute_sqlite "$MENU_DB" "DELETE FROM menu WHERE id='persian_calendar';"
fi

if [ -f "$ACL_DB" ]; then
    execute_sqlite "$ACL_DB" "DELETE FROM acl_group_permission WHERE id_resource=(SELECT id FROM acl_resource WHERE name='persian_calendar');"
    execute_sqlite "$ACL_DB" "DELETE FROM acl_resource WHERE name='persian_calendar';"
fi
echo -e "${GREEN}  ✔ رکوردها از دیتابیس پاک شدند.${NC}"

# 4. Remove Module Files
echo -e "${BLUE}[4/5] حذف پوشه ماژول $MODULE_DEST ...${NC}"
if [ -d "$MODULE_DEST" ]; then
    rm -rf "$MODULE_DEST"
    echo -e "${GREEN}  ✔ فایل‌های ماژول حذف شدند.${NC}"
fi

# 5. Clear Cache
echo -e "${BLUE}[5/5] پاکسازی کش قالب‌ها ...${NC}"
rm -rf /var/spool/issabel/smarty_cache/* 2>/dev/null || true
rm -rf "$WEB_ROOT/var/templates_c/"* 2>/dev/null || true

echo ""
echo -e "${GREEN}${BOLD}=================================================================="
echo "    ✔ ماژول با موفقیت کامل حذف شد و سیستم به حالت اولیه بازگشت.    "
echo "    Uninstallation completed successfully!                        "
echo "==================================================================${NC}"
