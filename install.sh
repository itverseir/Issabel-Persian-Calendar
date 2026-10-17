#!/bin/bash
# ==============================================================================
# Issabel PBX - Persian Calendar & Shamsi DatePicker Module Installer
# اسکریپت نصب خودکار ماژول تقویم شمسی برای ایزابل
# Developed by: Amir Safari - ITVERSE.IR
# Copyright (c) 2024-2026 Amir Safari - ITVERSE.IR. All rights reserved.
# مالکیت مادی و معنوی: امیر صفری - ITVERSE.IR
# ==============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Banner
echo -e "${CYAN}${BOLD}"
echo "=================================================================="
echo "    Issabel PBX - ماژول تقویم و تاریخ شمسی ایزابل                "
echo "    Shamsi DatePicker & System Date Integration                   "
echo "    توسعه‌دهنده: امیر صفری | Amir Safari - ITVERSE.IR            "
echo "=================================================================="
echo -e "${NC}"

# Check root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] لطفاً این اسکریپت را با دسترسی root اجرا کنید.${NC}"
    echo -e "${RED}[ERROR] Please run this script as root (sudo ./install.sh)${NC}"
    exit 1
fi

# Detect Issabel web root
WEB_ROOT="/var/www/html"
if [ ! -d "$WEB_ROOT" ]; then
    if [ -d "/usr/share/issabel" ]; then
        WEB_ROOT="/usr/share/issabel"
    else
        echo -e "${RED}[ERROR] دایرکتوری وب ایزابل یافت نشد (/var/www/html).${NC}"
        exit 1
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_SRC="$SCRIPT_DIR/modules/persian_calendar"
MODULE_DEST="$WEB_ROOT/modules/persian_calendar"
MENU_DB="/var/www/db/menu.db"
ACL_DB="/var/www/db/acl.db"
INDEX_FILE="$WEB_ROOT/index.php"
BACKUP_SUFFIX=".bak_$(date +%Y%m%d_%H%M%S)"

echo -e "${BLUE}[INFO] مسیر وب ایزابل: ${WEB_ROOT}${NC}"

# Status check option
if [ "$1" == "--status" ]; then
    echo -e "${BOLD}--- بررسی وضعیت ماژول ---${NC}"
    if [ -d "$MODULE_DEST" ]; then
        echo -e "دایرکتوری ماژول: ${GREEN}نصب شده${NC}"
    else
        echo -e "دایرکتوری ماژول: ${RED}نصب نشده${NC}"
    fi

    if grep -q "persian_hook.php" "$INDEX_FILE" 2>/dev/null; then
        echo -e "هوک index.php: ${GREEN}متصل است${NC}"
    else
        echo -e "هوک index.php: ${RED}متصل نیست${NC}"
    fi
    exit 0
fi

# 1. Copy Module Files
echo -e "${BLUE}[1/6] در حال کپی فایل‌های ماژول به مسیر $MODULE_DEST ...${NC}"
mkdir -p "$MODULE_DEST"
cp -r "$MODULE_SRC/"* "$MODULE_DEST/"

# Ensure configs/config.json exists and generate config.js
if [ ! -f "$MODULE_DEST/configs/config.json" ]; then
    cp "$MODULE_SRC/configs/config.json" "$MODULE_DEST/configs/config.json"
fi
php -r '
    $cfgFile = "'"$MODULE_DEST"'/configs/config.json";
    $jsFile  = "'"$MODULE_DEST"'/assets/js/config.js";
    $cfg = file_exists($cfgFile) ? file_get_contents($cfgFile) : "{}";
    file_put_contents($jsFile, "window.ISSABEL_PERSIAN_CONFIG = " . $cfg . ";\n");
' 2>/dev/null || true

# 2. Register Module in Issabel Menu Database
echo -e "${BLUE}[2/6] در حال ثبت ماژول در منوی سیستم (menu.db) ...${NC}"

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
    else
        echo -e "${YELLOW}[WARN] نه sqlite3 و نه php یافت نشد. ثبت منو نادیده گرفته شد.${NC}"
    fi
}

if [ -f "$MENU_DB" ]; then
    ORDER_COL="order_no"
    if sqlite3 "$MENU_DB" "PRAGMA table_info(menu);" 2>/dev/null | grep -q "|order|"; then
        ORDER_COL="order"
    fi
    execute_sqlite "$MENU_DB" "DELETE FROM menu WHERE id='persian_calendar';"
    execute_sqlite "$MENU_DB" "INSERT INTO menu (id, IdParent, Link, Name, Type, \"$ORDER_COL\") VALUES ('persian_calendar', 'system', '', 'تاریخ شمسی', 'module', 99);"
    echo -e "${GREEN}  ✔ ماژول با موفقیت در منوی System ثبت شد.${NC}"
fi

# 3. Register Permissions in ACL Database
echo -e "${BLUE}[3/6] در حال اعطای دسترسی به مدیر در acl.db ...${NC}"
if [ -f "$ACL_DB" ]; then
    RES_ID=$(sqlite3 "$ACL_DB" "SELECT id FROM acl_resource WHERE name='persian_calendar' LIMIT 1;" 2>/dev/null || echo "")
    if [ -z "$RES_ID" ]; then
        sqlite3 "$ACL_DB" "INSERT INTO acl_resource (name, description) VALUES ('persian_calendar', 'Persian Calendar Module');"
        RES_ID=$(sqlite3 "$ACL_DB" "SELECT id FROM acl_resource WHERE name='persian_calendar' LIMIT 1;" 2>/dev/null || echo "")
    else
        sqlite3 "$ACL_DB" "DELETE FROM acl_resource WHERE name='persian_calendar' AND id != $RES_ID;"
    fi

    if [ -n "$RES_ID" ]; then
        PERM_EXISTS=$(sqlite3 "$ACL_DB" "SELECT id FROM acl_group_permission WHERE id_action=1 AND id_group=1 AND id_resource=$RES_ID LIMIT 1;" 2>/dev/null || echo "")
        if [ -z "$PERM_EXISTS" ]; then
            sqlite3 "$ACL_DB" "INSERT INTO acl_group_permission (id_action, id_group, id_resource) VALUES (1, 1, $RES_ID);"
        fi
    fi
    echo -e "${GREEN}  ✔ مجوز دسترسی ادمین ثبت شد.${NC}"
fi

# 4. Inject Backend Hook into /var/www/html/index.php
echo -e "${BLUE}[4/6] در حال اتصال هوک بک‌اند در $INDEX_FILE ...${NC}"
if [ -f "$INDEX_FILE" ]; then
    if ! grep -q "persian_hook.php" "$INDEX_FILE"; then
        cp "$INDEX_FILE" "$INDEX_FILE$BACKUP_SUFFIX"
        echo -e "${YELLOW}  پشتیبان ایجاد شد: $INDEX_FILE$BACKUP_SUFFIX${NC}"

        php -r '
            $file = $argv[1];
            $content = file_get_contents($file);
            $hook = "\n// START ISSABEL PERSIAN CALENDAR HOOK\n" .
                    "if (file_exists(__DIR__ . '\''/modules/persian_calendar/libs/persian_hook.php'\'')) {\n" .
                    "    require_once __DIR__ . '\''/modules/persian_calendar/libs/persian_hook.php'\'';\n" .
                    "}\n" .
                    "// END ISSABEL PERSIAN CALENDAR HOOK\n";
            $new = preg_replace("/^<\\?php/i", "<?php" . $hook, $content, 1);
            if ($new && $new !== $content) {
                file_put_contents($file, $new);
            }
        ' "$INDEX_FILE"
        echo -e "${GREEN}  ✔ هوک بک‌اند با موفقیت متصل شد.${NC}"
    else
        echo -e "${YELLOW}  هوک بک‌اند قبلاً اضافه شده است.${NC}"
    fi
fi

# 5. Inject Frontend Assets into Themes and Popups
echo -e "${BLUE}[5/6] در حال اتصال استایل‌ها و دیت‌پیکر شمسی به قالب‌ها و پاپ‌آپ‌های ایزابل ...${NC}"
THEME_FILES=(
    "$WEB_ROOT/themes/tenant/_common/index.tpl"
    "$WEB_ROOT/themes/tenant/_common/popup.tpl"
    "$WEB_ROOT/themes/farsi_rtl/_common/index.tpl"
    "$WEB_ROOT/themes/farsi_rtl/_common/popup.tpl"
    "$WEB_ROOT/themes/elastixneo/_common/index.tpl"
    "$WEB_ROOT/themes/elastixneo/_common/popup.tpl"
    "$WEB_ROOT/themes/default/_common/index.tpl"
    "$WEB_ROOT/themes/default/_common/popup.tpl"
    "$WEB_ROOT/modules/cdrreport/themes/default/cel.tpl"
)

VERSION="1.1.0"
TAG_INJECT="<!-- START ISSABEL PERSIAN CALENDAR -->
<link rel=\"stylesheet\" type=\"text/css\" href=\"modules/persian_calendar/assets/css/persian-datepicker.css?v=$VERSION\" />
<link rel=\"stylesheet\" type=\"text/css\" href=\"modules/persian_calendar/assets/css/issabel-persian.css?v=$VERSION\" />
<script type=\"text/javascript\" src=\"modules/persian_calendar/assets/js/config.js?v=$VERSION\"></script>
<script type=\"text/javascript\" src=\"modules/persian_calendar/assets/js/issabel-persian.js?v=$VERSION\"></script>
<!-- END ISSABEL PERSIAN CALENDAR -->"

for TPL in "${THEME_FILES[@]}"; do
    if [ -f "$TPL" ]; then
        cp "$TPL" "$TPL$BACKUP_SUFFIX"
        php -r '
            $file = $argv[1];
            $tag = $argv[2];
            $c = file_get_contents($file);
            if (strpos($c, "<!-- START ISSABEL PERSIAN CALENDAR -->") !== false) {
                $c = preg_replace("/<!-- START ISSABEL PERSIAN CALENDAR -->.*?<!-- END ISSABEL PERSIAN CALENDAR -->/s", $tag, $c);
            } else if (strpos($c, "</head>") !== false) {
                $c = str_replace("</head>", $tag . "\n</head>", $c);
            } else {
                $c .= "\n" . $tag . "\n";
            }
            file_put_contents($file, $c);
        ' "$TPL" "$TAG_INJECT"
        echo -e "${GREEN}  ✔ قالب $(basename $(dirname $(dirname "$TPL")))/$(basename "$TPL") با موفقیت به‌روزرسانی شد.${NC}"
    fi
done

# Patch translateDate in misc.lib.php for universal format support
MISC_LIB="$WEB_ROOT/libs/misc.lib.php"
if [ -f "$MISC_LIB" ]; then
    if ! grep -q "translateDate - Persian support" "$MISC_LIB"; then
        cp "$MISC_LIB" "$MISC_LIB$BACKUP_SUFFIX"
        php -r '
            $file = $argv[1];
            $c = file_get_contents($file);
            $search = "function translateDate(" . "\$dateOrig)";
            $pos = strpos($c, $search);
            if ($pos !== false) {
                $bracePos = strpos($c, "{", $pos);
                if ($bracePos !== false) {
                    $insert = "{\n    // translateDate - Persian support (ISO & standard)\n" .
                              "    \$dateOrig = trim(\$dateOrig);\n" .
                              "    if (preg_match(\"/^([[:digit:]]{4})[-\\/]([[:digit:]]{1,2})[-\\/]([[:digit:]]{1,2})/\", \$dateOrig, \$mIso)) {\n" .
                              "        return sprintf(\"%04d-%02d-%02d\", \$mIso[1], \$mIso[2], \$mIso[3]);\n" .
                              "    }\n";
                    $c = substr_replace($c, $insert, $bracePos, 1);
                    file_put_contents($file, $c);
                }
            }
        ' "$MISC_LIB"
        echo -e "${GREEN}  ✔ تابع translateDate برای سازگاری کامل گزارشات به‌روزرسانی شد.${NC}"
    fi
fi

# 6. Patch Time Groups and Time Conditions for Persian Calendar Support
echo -e "${BLUE}[6/7] در حال فعال‌سازی پشتیبانی تقویم شمسی در تایم‌گروپ (Time Groups) ...${NC}"
TC_FUNCS="$WEB_ROOT/admin/modules/timeconditions/functions.inc.php"
TC_PAGE="$WEB_ROOT/admin/modules/timeconditions/page.timegroups.php"

if [ -f "$TC_FUNCS" ]; then
    if ! grep -q "ISSABEL PERSIAN TIMEGROUPS HOOK" "$TC_FUNCS"; then
        cp "$TC_FUNCS" "$TC_FUNCS$BACKUP_SUFFIX"
        php -r '
            $f = $argv[1];
            $c = file_get_contents($f);

            // 1. Hook at the top
            $hook = "\n// START ISSABEL PERSIAN TIMEGROUPS HOOK\n" .
                    "if (file_exists(\"/var/www/html/modules/persian_calendar/libs/timegroups_persian.php\")) {\n" .
                    "    require_once \"/var/www/html/modules/persian_calendar/libs/timegroups_persian.php\";\n" .
                    "}\n" .
                    "// END ISSABEL PERSIAN TIMEGROUPS HOOK\n";
            $c = preg_replace("/<\\?php/i", "<?php" . $hook, $c, 1);

            // 2. Expand Shamsi rules in GotoIfTime
            $searchGoto = "\$ext->add(\$context, \$time_id, " . "\x27\x27, new ext_gotoiftime(" . "\$time[1]," . "\x27truestate\x27));";
            $replaceGoto = "\$expanded = function_exists(\"issabel_expand_shamsi_time_rule\") ? issabel_expand_shamsi_time_rule(\$time[1]) : array(\$time[1]);\n" .
                           "                        foreach (\$expanded as \$expTime) {\n" .
                           "                            \$ext->add(\$context, \$time_id, " . "\x27\x27, new ext_gotoiftime(" . "\$expTime," . "\x27truestate\x27));\n" .
                           "                        }";
            if (strpos($c, $searchGoto) !== false) {
                $c = str_replace($searchGoto, $replaceGoto, $c);
            }

            // 3. wday_start
            $markerWdayStart = "<select name=\"\x27.\$name.\x27[wday_start]\">\x27;";
            $pos1 = strpos($c, $markerWdayStart);
            if ($pos1 !== false) {
                $pos2 = strpos($c, "\$html = \$html.\x27</td>\x27;", $pos1);
                if ($pos2 !== false) {
                    $replacement = "<select name=\"\x27.\$name.\x27[wday_start]\">\x27;\n" .
                                   "    if (function_exists(\"issabel_draw_wday_options\")) {\n" .
                                   "        \$html = \$html . issabel_draw_wday_options(\$wday_start);\n" .
                                   "    }\n" .
                                   "    \$html = \$html.\x27</select>\x27;\n    ";
                    $c = substr_replace($c, $replacement, $pos1, $pos2 - $pos1);
                }
            }

            // 4. wday_finish
            $markerWdayFinish = "<select name=\"\x27.\$name.\x27[wday_finish]\">\x27;";
            $pos1 = strpos($c, $markerWdayFinish);
            if ($pos1 !== false) {
                $pos2 = strpos($c, "\$html = \$html.\x27</td>\x27;", $pos1);
                if ($pos2 !== false) {
                    $replacement = "<select name=\"\x27.\$name.\x27[wday_finish]\">\x27;\n" .
                                   "    if (function_exists(\"issabel_draw_wday_options\")) {\n" .
                                   "        \$html = \$html . issabel_draw_wday_options(\$wday_finish);\n" .
                                   "    }\n" .
                                   "    \$html = \$html.\x27</select>\x27;\n    ";
                    $c = substr_replace($c, $replacement, $pos1, $pos2 - $pos1);
                }
            }

            // 5. month_start
            $markerMonthStart = "<select name=\"\x27.\$name.\x27[month_start]\">\x27;";
            $pos1 = strpos($c, $markerMonthStart);
            if ($pos1 !== false) {
                $pos2 = strpos($c, "\$html = \$html.\x27</td>\x27;", $pos1);
                if ($pos2 !== false) {
                    $replacement = "<select name=\"\x27.\$name.\x27[month_start]\">\x27;\n" .
                                   "    if (function_exists(\"issabel_draw_month_options\")) {\n" .
                                   "        \$html = \$html . issabel_draw_month_options(\$month_start);\n" .
                                   "    }\n" .
                                   "    \$html = \$html.\x27</select>\x27;\n    ";
                    $c = substr_replace($c, $replacement, $pos1, $pos2 - $pos1);
                }
            }

            // 6. month_finish
            $markerMonthFinish = "<select name=\"\x27.\$name.\x27[month_finish]\">\x27;";
            $pos1 = strpos($c, $markerMonthFinish);
            if ($pos1 !== false) {
                $pos2 = strpos($c, "\$html = \$html.\x27</td>\x27;", $pos1);
                if ($pos2 !== false) {
                    $replacement = "<select name=\"\x27.\$name.\x27[month_finish]\">\x27;\n" .
                                   "    if (function_exists(\"issabel_draw_month_options\")) {\n" .
                                   "        \$html = \$html . issabel_draw_month_options(\$month_finish);\n" .
                                   "    }\n" .
                                   "    \$html = \$html.\x27</select>\x27;\n    ";
                    $c = substr_replace($c, $replacement, $pos1, $pos2 - $pos1);
                }
            }

            file_put_contents($f, $c);
        ' "$TC_FUNCS"
        echo -e "${GREEN}  ✔ موتور تایم‌گروپ استریسک (functions.inc.php) با موفقیت پچ شد.${NC}"
    fi
fi

if [ -f "$TC_PAGE" ]; then
    if ! grep -q "issabel_get_shamsi_now_string" "$TC_PAGE"; then
        cp "$TC_PAGE" "$TC_PAGE$BACKUP_SUFFIX"
        php -r '
            $f = $argv[1];
            $c = file_get_contents($f);
            $new = "<div class=\"rnav\" style=\"margin:15px 10px; padding: 6px 12px; background: #eaf2f8; border: #2E78A7 solid 1px; border-radius: 4px; min-height: 1.2em !important; font-family: Tahoma, Arial, sans-serif;\">\n" .
                   "\t<b><?php echo _(\"Server time\")?>:</b> \n" .
                   "\t<?php if (file_exists(\"/var/www/html/modules/persian_calendar/libs/timegroups_persian.php\")) { require_once \"/var/www/html/modules/persian_calendar/libs/timegroups_persian.php\"; echo \"<span style=\\\"color:#005580; font-weight:bold;\\\">\" . issabel_get_shamsi_now_string() . \"</span> | \"; } ?>\n" .
                   "\t<span id=\"idTime\" style=\"font-weight: bold; color: #222;\">00:00:00</span>\n" .
                   "</div>";
            $c = preg_replace("/<div class=\"rnav\"[^>]*>\\s*<\\?php echo _\\(\"Server time\"\\)\\s*\\?>:\\s*<span id=\"idTime\">00:00:00<\\/span>\\s*<\\/div>/s", $new, $c);
            file_put_contents($f, $c);
        ' "$TC_PAGE"
        echo -e "${GREEN}  ✔ نمایش زنده تاریخ شمسی در سربرگ تایم‌گروپ (page.timegroups.php) فعال شد.${NC}"
    fi
fi

# 7. Permissions and Cache Cleaning
echo -e "${BLUE}[7/7] در حال تنظیم دسترسی فایل‌ها و پاکسازی کش قالب‌ها ...${NC}"
chown -R asterisk:asterisk "$MODULE_DEST" 2>/dev/null || chown -R apache:apache "$MODULE_DEST" 2>/dev/null || true
chmod -R 755 "$MODULE_DEST"
chmod 666 "$MODULE_DEST/configs/config.json" 2>/dev/null || true
chmod 666 "$MODULE_DEST/assets/js/config.js" 2>/dev/null || true

# Clear Smarty template cache
rm -rf /var/spool/issabel/smarty_cache/* 2>/dev/null || true
rm -rf "$WEB_ROOT/var/templates_c/"* 2>/dev/null || true

echo ""
echo -e "${GREEN}${BOLD}=================================================================="
echo "    ✔ نصب با موفقیت کامل انجام شد!                                "
echo "    Installation completed successfully!                          "
echo "==================================================================${NC}"
echo -e "${CYAN}"
echo "امکانات اضافه شده:"
echo "  1. دیت‌پیکر شمسی در تمامی فرم‌ها و گزارشات (CDR، مانیتورینگ و ...)"
echo "  2. نمایش تاریخ‌ها به صورت شمسی در تمامی جداول با راهنمای میلادی"
echo "  3. ساعت و تاریخ زنده شمسی در بالای صفحه سیستم"
echo "  4. منوی مدیریت ماژول در پنل ایزابل -> منوی System -> تاریخ شمسی"
echo "  5. پشتیبانی از ماه‌ها و روزهای شمسی در تایم‌گروپ (Time Groups & Time Conditions)"
echo ""
echo "جهت ورود به پنل، صفحه مرورگر خود را با Ctrl + F5 رفرش نمایید."
echo -e "${NC}"
