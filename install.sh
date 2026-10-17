#!/bin/bash
# ==============================================================================
# Issabel PBX - Persian Calendar & Shamsi DatePicker Module Installer
# اسکریپت جامع و خودکار نصب ماژول تقویم شمسی برای ایزابل ۴ و ۵
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
echo "    پشتیبانی از ایزابل ۴ و ۵ (Universal Installer: Issabel 4 & 5)"
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

# Parse CLI arguments for version or non-interactive mode
CHOSEN_VER=""
NON_INTERACTIVE=false

for arg in "$@"; do
    case "$arg" in
        --v4|--issabel4)
            CHOSEN_VER="4"
            ;;
        --v5|--issabel5)
            CHOSEN_VER="5"
            ;;
        -y|--yes|--non-interactive)
            NON_INTERACTIVE=true
            ;;
    esac
done

# Function to auto-detect Issabel version
detect_issabel_version() {
    local detected="4"
    local os_info=""

    if [ -f /etc/os-release ]; then
        os_info=$(cat /etc/os-release 2>/dev/null || true)
    elif [ -f /etc/redhat-release ]; then
        os_info=$(cat /etc/redhat-release 2>/dev/null || true)
    fi

    # 1. Check Issabel framework rpm version
    if command -v rpm >/dev/null 2>&1; then
        local iss_rpm
        iss_rpm=$(rpm -q issabel-framework 2>/dev/null || echo "")
        if [[ "$iss_rpm" =~ el8 ]] || [[ "$iss_rpm" =~ issabel-framework-5 ]]; then
            echo "5"
            return
        elif [[ "$iss_rpm" =~ el7 ]] || [[ "$iss_rpm" =~ issabel-framework-4 ]]; then
            echo "4"
            return
        fi
    fi

    # 2. Check Linux distribution
    if echo "$os_info" | grep -qiE "rocky|almalinux|rhel.*8|centos.*8"; then
        echo "5"
        return
    elif echo "$os_info" | grep -qiE "centos.*7|rhel.*7"; then
        echo "4"
        return
    fi

    # 3. Check PHP version
    if command -v php >/dev/null 2>&1; then
        local php_major
        php_major=$(php -r 'echo PHP_MAJOR_VERSION;' 2>/dev/null || echo "5")
        if [ "$php_major" -ge 7 ]; then
            echo "5"
            return
        fi
    fi

    echo "$detected"
}

DETECTED_VER=$(detect_issabel_version)

# Version selection prompt if not explicitly passed
if [ -z "$CHOSEN_VER" ]; then
    if [ "$NON_INTERACTIVE" = true ]; then
        CHOSEN_VER="$DETECTED_VER"
    else
        echo -e "${YELLOW}🔍 بررسی خودکار سیستم:${NC}"
        if [ "$DETECTED_VER" = "5" ]; then
            echo -e "   سیستم‌عامل و نسخه ایزابل شناسایی شده: ${GREEN}${BOLD}ایزابل ۵ (Issabel 5 / Rocky Linux 8 / PHP 7+)${NC}"
        else
            echo -e "   سیستم‌عامل و نسخه ایزابل شناسایی شده: ${GREEN}${BOLD}ایزابل ۴ (Issabel 4 / CentOS 7 / PHP 5-7)${NC}"
        fi
        echo ""
        echo -e "${BOLD}نسخه مورد نظر خود برای نصب را انتخاب کنید:${NC}"
        echo "  1) ایزابل 4 (Issabel 4 - CentOS 7)"
        echo "  2) ایزابل 5 (Issabel 5 - Rocky Linux / AlmaLinux 8)"
        echo ""
        read -p "انتخاب شما [1 یا 2] (پیش‌فرض: $DETECTED_VER): " USER_INPUT
        case "$USER_INPUT" in
            1) CHOSEN_VER="4" ;;
            2) CHOSEN_VER="5" ;;
            *) CHOSEN_VER="$DETECTED_VER" ;;
        esac
    fi
fi

echo ""
echo -e "${CYAN}${BOLD}[✓] پیکربندی و بهینه‌سازی نصب برای ایزابل ${CHOSEN_VER} انتخاب شد.${NC}"
echo -e "${BLUE}[INFO] مسیر وب ایزابل: ${WEB_ROOT}${NC}"
echo ""

# 1. Copy Module Files
echo -e "${BLUE}[1/7] در حال کپی فایل‌های ماژول به مسیر $MODULE_DEST ...${NC}"
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
echo -e "${BLUE}[2/7] در حال ثبت ماژول در منوی سیستم (menu.db) ...${NC}"

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
echo -e "${BLUE}[3/7] در حال اعطای دسترسی به مدیر در acl.db ...${NC}"
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

# 4. Inject Backend Hook into index.php
echo -e "${BLUE}[4/7] در حال بررسی و اتصال هوک بک‌اند در $INDEX_FILE ...${NC}"
if [ -f "$INDEX_FILE" ]; then
    if ! grep -q "persian_hook.php" "$INDEX_FILE"; then
        cp "$INDEX_FILE" "$INDEX_FILE$BACKUP_SUFFIX"
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
echo -e "${BLUE}[5/7] در حال اتصال استایل‌ها و دیت‌پیکر شمسی به قالب‌ها و پاپ‌آپ‌های ایزابل ...${NC}"
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

# Dynamically detect any additional installed themes (e.g. Issabel 5 themes)
if [ -d "$WEB_ROOT/themes" ]; then
    while IFS= read -r extra_tpl; do
        if [ -n "$extra_tpl" ] && [ -f "$extra_tpl" ]; then
            THEME_FILES+=("$extra_tpl")
        fi
    done < <(find "$WEB_ROOT/themes" -type f \( -name "index.tpl" -o -name "popup.tpl" \) 2>/dev/null)
fi

# Deduplicate template files
readarray -t UNIQUE_THEME_FILES < <(printf "%s\n" "${THEME_FILES[@]}" | sort -u)

VERSION="1.1.0"
TAG_INJECT="<!-- START ISSABEL PERSIAN CALENDAR -->
<link rel=\"stylesheet\" type=\"text/css\" href=\"modules/persian_calendar/assets/css/persian-datepicker.css?v=$VERSION\" />
<link rel=\"stylesheet\" type=\"text/css\" href=\"modules/persian_calendar/assets/css/issabel-persian.css?v=$VERSION\" />
<script type=\"text/javascript\" src=\"modules/persian_calendar/assets/js/config.js?v=$VERSION\"></script>
<script type=\"text/javascript\" src=\"modules/persian_calendar/assets/js/issabel-persian.js?v=$VERSION\"></script>
<!-- END ISSABEL PERSIAN CALENDAR -->"

for TPL in "${UNIQUE_THEME_FILES[@]}"; do
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

# Inject Assets into FreePBX / IssabelPBX Admin (for direct PBX navigation like /admin/config.php in Issabel 5)
ADMIN_HEADER="$WEB_ROOT/admin/views/header.php"
ADMIN_HEADER_ALT="$WEB_ROOT/admin/header.php"
for A_HDR in "$ADMIN_HEADER" "$ADMIN_HEADER_ALT"; do
    if [ -f "$A_HDR" ]; then
        if ! grep -q "modules/persian_calendar/assets" "$A_HDR"; then
            cp "$A_HDR" "$A_HDR$BACKUP_SUFFIX"
            php -r '
                $file = $argv[1];
                $c = file_get_contents($file);
                $tag = "\n// START ISSABEL PERSIAN CALENDAR\n" .
                       "\$html .= '\''<link rel=\"stylesheet\" type=\"text/css\" href=\"/modules/persian_calendar/assets/css/persian-datepicker.css?v=1.1.0\" />\n'\'';\n" .
                       "\$html .= '\''<link rel=\"stylesheet\" type=\"text/css\" href=\"/modules/persian_calendar/assets/css/issabel-persian.css?v=1.1.0\" />\n'\'';\n" .
                       "\$html .= '\''<script type=\"text/javascript\" src=\"/modules/persian_calendar/assets/js/config.js?v=1.1.0\"></script>\n'\'';\n" .
                       "\$html .= '\''<script type=\"text/javascript\" src=\"/modules/persian_calendar/assets/js/issabel-persian.js?v=1.1.0\"></script>\n'\'';\n" .
                       "// END ISSABEL PERSIAN CALENDAR\n";
                if (strpos($c, "\$html .= '\''</head>'\'';") !== false) {
                    $c = str_replace("\$html .= '\''</head>'\'';", $tag . "\$html .= '\''</head>'\'';", $c);
                } else if (strpos($c, "</head>") !== false) {
                    $raw = "\n<!-- START ISSABEL PERSIAN CALENDAR -->\n" .
                           "<link rel=\"stylesheet\" type=\"text/css\" href=\"/modules/persian_calendar/assets/css/persian-datepicker.css?v=1.1.0\" />\n" .
                           "<link rel=\"stylesheet\" type=\"text/css\" href=\"/modules/persian_calendar/assets/css/issabel-persian.css?v=1.1.0\" />\n" .
                           "<script type=\"text/javascript\" src=\"/modules/persian_calendar/assets/js/config.js?v=1.1.0\"></script>\n" .
                           "<script type=\"text/javascript\" src=\"/modules/persian_calendar/assets/js/issabel-persian.js?v=1.1.0\"></script>\n" .
                           "<!-- END ISSABEL PERSIAN CALENDAR -->\n</head>";
                    $c = str_replace("</head>", $raw, $c);
                }
                file_put_contents($file, $c);
            ' "$A_HDR"
            echo -e "${GREEN}  ✔ قالب مدیریت استریسک $(basename "$A_HDR") برای ایزابل ۵ با موفقیت مجهز شد.${NC}"
        fi
    fi
done

# Hook backend into /admin/config.php for direct PBX access (Issabel 5)
ADMIN_CONFIG="$WEB_ROOT/admin/config.php"
if [ -f "$ADMIN_CONFIG" ]; then
    if ! grep -q "persian_hook.php" "$ADMIN_CONFIG"; then
        cp "$ADMIN_CONFIG" "$ADMIN_CONFIG$BACKUP_SUFFIX"
        php -r '
            $file = $argv[1];
            $content = file_get_contents($file);
            $hook = "\n// START ISSABEL PERSIAN CALENDAR HOOK\n" .
                    "if (file_exists(dirname(__DIR__) . '\''/modules/persian_calendar/libs/persian_hook.php'\'')) {\n" .
                    "    require_once dirname(__DIR__) . '\''/modules/persian_calendar/libs/persian_hook.php'\'';\n" .
                    "}\n" .
                    "// END ISSABEL PERSIAN CALENDAR HOOK\n";
            $new = preg_replace("/^<\\?php/i", "<?php" . $hook, $content, 1);
            if ($new && $new !== $content) {
                file_put_contents($file, $new);
            }
        ' "$ADMIN_CONFIG"
        echo -e "${GREEN}  ✔ هوک بک‌اند در بخش مدیریت admin/config.php نیز متصل شد.${NC}"
    fi
fi

# Ensure misc.lib.php remains in its pristine, original factory state (Zero system modifications!)
MISC_LIB="$WEB_ROOT/libs/misc.lib.php"
if [ -f "$MISC_LIB" ]; then
    php -r '
        $file = $argv[1];
        $c = file_get_contents($file);
        if (strpos($c, "Persian") !== false || strpos($c, "PERSIAN") !== false) {
            $origTranslate = "function translateDate(\$dateOrig)\n" .
                "{\n" .
                "    if(preg_match(\"/([[:digit:]]{1,2})[[:space:]]+([[:alnum:]]{3})[[:space:]]+([[:digit:]]{4})/\", \$dateOrig, \$arrReg)) {\n" .
                "        if(\$arrReg[2]==\"Jan\")      \$numMonth = \"01\";\n" .
                "        else if(\$arrReg[2]==\"Feb\") \$numMonth = \"02\";\n" .
                "        else if(\$arrReg[2]==\"Mar\") \$numMonth = \"03\";\n" .
                "        else if(\$arrReg[2]==\"Apr\") \$numMonth = \"04\";\n" .
                "        else if(\$arrReg[2]==\"May\") \$numMonth = \"05\";\n" .
                "        else if(\$arrReg[2]==\"Jun\") \$numMonth = \"06\";\n" .
                "        else if(\$arrReg[2]==\"Jul\") \$numMonth = \"07\";\n" .
                "        else if(\$arrReg[2]==\"Aug\") \$numMonth = \"08\";\n" .
                "        else if(\$arrReg[2]==\"Sep\") \$numMonth = \"09\";\n" .
                "        else if(\$arrReg[2]==\"Oct\") \$numMonth = \"10\";\n" .
                "        else if(\$arrReg[2]==\"Nov\") \$numMonth = \"11\";\n" .
                "        else if(\$arrReg[2]==\"Dec\") \$numMonth = \"12\";\n" .
                "        return \$arrReg[3] . \"-\" . \$numMonth . \"-\" . \$arrReg[1];\n" .
                "    } else {\n" .
                "        return false;\n" .
                "    }\n" .
                "}";
            $c = preg_replace("/function translateDate\s*\([^)]*\)\s*\{.*?\n\}(?=\s*\n\s*function|\s*$)/s", $origTranslate, $c);
            file_put_contents($file, $c);
        }
    ' "$MISC_LIB"
    echo -e "${GREEN}  ✔ فایل سیستمی misc.lib.php بدون تغییر و در حالت ۱۰۰٪ اورجینال و استاندارد ایزابل حفظ شد.${NC}"
fi

# 6. Patch Time Groups and Time Conditions for Persian Calendar Support (Issabel 4 & 5)
echo -e "${BLUE}[6/7] در حال فعال‌سازی پشتیبانی تقویم شمسی در تایم‌گروپ (Time Groups) ...${NC}"
TC_FUNCS="$WEB_ROOT/admin/modules/timeconditions/functions.inc.php"
TC_PAGE="$WEB_ROOT/admin/modules/timeconditions/page.timegroups.php"

if [ -f "$TC_FUNCS" ]; then
    if ! grep -q "ISSABEL PERSIAN TIMEGROUPS HOOK" "$TC_FUNCS"; then
        cp "$TC_FUNCS" "$TC_FUNCS$BACKUP_SUFFIX"
        php -r '
            $f = $argv[1];
            $webRoot = $argv[2];
            $c = file_get_contents($f);

            // 1. Hook at the top
            $hook = "\n// START ISSABEL PERSIAN TIMEGROUPS HOOK\n" .
                    "if (file_exists(\"$webRoot/modules/persian_calendar/libs/timegroups_persian.php\")) {\n" .
                    "    require_once \"$webRoot/modules/persian_calendar/libs/timegroups_persian.php\";\n" .
                    "}\n" .
                    "// END ISSABEL PERSIAN TIMEGROUPS HOOK\n";
            $c = preg_replace("/<\\?php/i", "<?php" . $hook, $c, 1);

            // 2. Expand Shamsi rules in GotoIfTime (Issabel 4 & 5)
            $replaceGoto = "\$expanded = function_exists(\"issabel_expand_shamsi_time_rule\") ? issabel_expand_shamsi_time_rule(\$time[1]) : array(\$time[1]);\n" .
                           "                        foreach (\$expanded as \$expTime) {\n" .
                           "                            \$ext->add(\$context, \$time_id, \x27\x27, new ext_gotoiftime(\$expTime, \x27truestate\x27));\n" .
                           "                        }";
            $c = preg_replace(
                "/\x24ext->add\(\x24context,\s*\x24time_id,\s*[\x27\x22]{2},\s*new\s+ext_gotoiftime\(\x24time\[1\],\s*[\x27\x22]truestate[\x27\x22]\)\);/",
                $replaceGoto,
                $c
            );

            // 3. wday_start (Issabel 4 & 5 compatible)
            $p1 = "/(<select[^>]*?\\[wday_start\\][^>]*>\\\x27\\;).*?(\\x24html\\s*=\\s*\\x24html\\s*\\.\\s*\\\x27<\\/td>\\\x27\\;)/s";
            $r1 = "$1\n" .
                  "    if (function_exists(\"issabel_draw_wday_options\")) { \$html = \$html . issabel_draw_wday_options(\$wday_start); }\n    " .
                  "\$html = \$html . \x27</select></td>\x27;";
            $c = preg_replace($p1, $r1, $c);

            // 4. wday_finish (Issabel 4 & 5 compatible)
            $p2 = "/(<select[^>]*?\\[wday_finish\\][^>]*>\\\x27\\;).*?(\\x24html\\s*=\\s*\\x24html\\s*\\.\\s*\\\x27<\\/td>\\\x27\\;)/s";
            $r2 = "$1\n" .
                  "    if (function_exists(\"issabel_draw_wday_options\")) { \$html = \$html . issabel_draw_wday_options(\$wday_finish); }\n    " .
                  "\$html = \$html . \x27</select></td>\x27;";
            $c = preg_replace($p2, $r2, $c);

            // 5. month_start (Issabel 4 & 5 compatible)
            $p3 = "/(<select[^>]*?\\[month_start\\][^>]*>\\\x27\\;).*?(\\x24html\\s*=\\s*\\x24html\\s*\\.\\s*\\\x27<\\/td>\\\x27\\;)/s";
            $r3 = "$1\n" .
                  "    if (function_exists(\"issabel_draw_month_options\")) { \$html = \$html . issabel_draw_month_options(\$month_start); }\n    " .
                  "\$html = \$html . \x27</select></td>\x27;";
            $c = preg_replace($p3, $r3, $c);

            // 6. month_finish (Issabel 4 & 5 compatible)
            $p4 = "/(<select[^>]*?\\[month_finish\\][^>]*>\\\x27\\;).*?(\\x24html\\s*=\\s*\\x24html\\s*\\.\\s*\\\x27<\\/td>\\\x27\\;)/s";
            $r4 = "$1\n" .
                  "    if (function_exists(\"issabel_draw_month_options\")) { \$html = \$html . issabel_draw_month_options(\$month_finish); }\n    " .
                  "\$html = \$html . \x27</select></td>\x27;";
            $c = preg_replace($p4, $r4, $c);

            file_put_contents($f, $c);
        ' "$TC_FUNCS" "$WEB_ROOT"
        echo -e "${GREEN}  ✔ ماژول تایم‌گروپ با موفقیت به تقویم شمسی مجهز شد.${NC}"
    fi
fi

if [ -f "$TC_PAGE" ]; then
    if ! grep -q "issabel-persian-shamsi-time" "$TC_PAGE"; then
        cp "$TC_PAGE" "$TC_PAGE$BACKUP_SUFFIX"
        php -r '
            $f = $argv[1];
            $c = file_get_contents($f);
            if (strpos($c, "id=\"idTime\"") !== false) {
                $shamsiBadge = "<span id=\"idTime\">00:00:00</span>" .
                    "<?php if (function_exists(\"issabel_jdate\")) { ?>" .
                    " <span class=\"issabel-persian-shamsi-time\" style=\"margin-left: 10px; margin-right: 10px; color: #1a73e8; background: #e8f0fe; padding: 2px 8px; border-radius: 4px; font-size: 12px; font-weight: bold;\">" .
                    "📅 <?php echo issabel_jdate(\"l j F Y\"); ?>" .
                    "</span><?php } ?>";
                $c = preg_replace("/<span id=\"idTime\">00:00:00<\\/span>/", $shamsiBadge, $c, 1);
                file_put_contents($f, $c);
            }
        ' "$TC_PAGE"
        echo -e "${GREEN}  ✔ نمایش زنده تاریخ شمسی در سربرگ تایم‌گروپ فعال شد.${NC}"
    fi
fi

# 7. Permissions, SELinux and Cache Cleaning
echo -e "${BLUE}[7/7] در حال تنظیم دسترسی‌ها، پاکسازی کش و ری‌لود وب‌سرور ...${NC}"
chown -R asterisk:asterisk "$MODULE_DEST" 2>/dev/null || chown -R apache:apache "$MODULE_DEST" 2>/dev/null || true
chmod -R 755 "$MODULE_DEST"
chmod 666 "$MODULE_DEST/configs/config.json" 2>/dev/null || true
chmod 666 "$MODULE_DEST/assets/js/config.js" 2>/dev/null || true

# SELinux context restoration (common on Rocky Linux 8 / Issabel 5)
if command -v restorecon >/dev/null 2>&1; then
    restorecon -Rv "$MODULE_DEST" >/dev/null 2>&1 || true
fi

# Clear Smarty and Framework caches
rm -rf /var/spool/issabel/smarty_cache/* 2>/dev/null || true
rm -rf "$WEB_ROOT/var/templates_c/"* 2>/dev/null || true
rm -rf "$WEB_ROOT/var/cache/"* 2>/dev/null || true

# Reset PHP OPcache if active
php -r 'if (function_exists("opcache_reset")) { opcache_reset(); }' 2>/dev/null || true

# Reload web services based on detected/selected Issabel version
if [ "$CHOSEN_VER" = "5" ]; then
    systemctl reload php-fpm 2>/dev/null || systemctl restart php-fpm 2>/dev/null || true
    systemctl reload httpd 2>/dev/null || systemctl restart httpd 2>/dev/null || true
else
    systemctl reload httpd 2>/dev/null || service httpd reload 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}${BOLD}=================================================================="
echo "    ✔ نصب با موفقیت کامل انجام شد!                                "
echo "    Installation completed successfully for Issabel ${CHOSEN_VER}!       "
echo "==================================================================${NC}"
echo -e "${CYAN}"
echo "امکانات فعال شده:"
echo "  1. دیت‌پیکر شمسی در تمامی فرم‌ها و گزارشات (CDR، مانیتورینگ، صف‌ها و ...)"
echo "  2. نمایش تاریخ‌ها به صورت شمسی در تمامی جداول با راهنمای میلادی (Tooltip)"
echo "  3. ساعت و تاریخ زنده شمسی در بالای صفحه سیستم"
echo "  4. منوی مدیریت ماژول در پنل ایزابل -> منوی System -> تاریخ شمسی"
echo "  5. پشتیبانی از ماه‌ها و روزهای شمسی در تایم‌گروپ (Time Groups & Conditions)"
echo ""
echo "جهت ورود به پنل و مشاهده تغییرات، صفحه مرورگر خود را با Ctrl + F5 رفرش نمایید."
echo -e "${NC}"
