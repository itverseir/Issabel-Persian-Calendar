<?php
/**
 * Safe Time Groups & Time Conditions Persian Engine Patcher for Issabel 4 & 5
 * Developed by: Amir Safari - ITVERSE.IR
 */

$webRoot = isset($argv[1]) ? rtrim($argv[1], '/\\') : '/var/www/html';
$action  = isset($argv[2]) ? $argv[2] : 'install';

$tcFuncs = "$webRoot/admin/modules/timeconditions/functions.inc.php";
$tcPage  = "$webRoot/admin/modules/timeconditions/page.timegroups.php";

if ($action === 'uninstall') {
    // Restore functions.inc.php
    if (file_exists($tcFuncs)) {
        $c = file_get_contents($tcFuncs);
        if (strpos($c, 'ISSABEL PERSIAN TIMEGROUPS HOOK') !== false) {
            $baks = glob($tcFuncs . '.bak_*');
            if (!empty($baks)) {
                rsort($baks);
                copy($baks[0], $tcFuncs);
                echo "Restored functions.inc.php from backup.\n";
            }
        }
    }
    // Restore page.timegroups.php
    if (file_exists($tcPage)) {
        $c = file_get_contents($tcPage);
        if (strpos($c, 'issabel-persian-shamsi-time') !== false) {
            $baks = glob($tcPage . '.bak_*');
            if (!empty($baks)) {
                rsort($baks);
                copy($baks[0], $tcPage);
                echo "Restored page.timegroups.php from backup.\n";
            }
        }
    }
    exit(0);
}

// INSTALL ACTION
if (file_exists($tcFuncs)) {
    $c = file_get_contents($tcFuncs);
    if (strpos($c, 'ISSABEL PERSIAN TIMEGROUPS HOOK') === false) {
        $bak = $tcFuncs . '.bak_' . date('Ymd_His');
        copy($tcFuncs, $bak);

        // 1. Hook at the top
        $hook = "\n// START ISSABEL PERSIAN TIMEGROUPS HOOK\n" .
                "if (file_exists('$webRoot/modules/persian_calendar/libs/timegroups_persian.php')) {\n" .
                "    require_once '$webRoot/modules/persian_calendar/libs/timegroups_persian.php';\n" .
                "}\n" .
                "// END ISSABEL PERSIAN TIMEGROUPS HOOK\n";
        $c = preg_replace('/<\?php/i', '<?php' . $hook, $c, 1);

        // 2. Expand Shamsi rules in GotoIfTime
        $replaceGoto = "\$expanded = function_exists('issabel_expand_shamsi_time_rule') ? issabel_expand_shamsi_time_rule(\$time[1]) : array(\$time[1]);\n" .
                       "                        foreach (\$expanded as \$expTime) {\n" .
                       "                            \$ext->add(\$context, \$time_id, '', new ext_gotoiftime(\$expTime, 'truestate'));\n" .
                       "                        }";
        $c = preg_replace(
            '/\$ext->add\(\$context,\s*\$time_id,\s*[\'\"]{2},\s*new\s+ext_gotoiftime\(\$time\[1\],\s*[\'\"]truestate[\'\"]\)\);/',
            $replaceGoto,
            $c
        );

        // 3. Patch select dropdowns (wday_start, wday_finish, month_start, month_finish)
        function patch_select_block(&$content, $fieldName, $functionCall) {
            $needle = '[' . $fieldName . ']';
            $offset = 0;
            while (($pos = strpos($content, $needle, $offset)) !== false) {
                $before = substr($content, max(0, $pos - 150), min(150, $pos));
                $selectPos = strrpos($before, '<select');
                if ($selectPos !== false) {
                    $actualSelectPos = max(0, $pos - 150) + $selectPos;
                    $tagClosePos = strpos($content, ">';", $actualSelectPos);
                    if ($tagClosePos !== false) {
                        $tagClosePos += 3;
                        $tdClosePos = strpos($content, "'</td>';", $tagClosePos);
                        if ($tdClosePos !== false) {
                            $tdClosePos += 8;
                            $funcName = strtok($functionCall, '(');
                            $replacement = "\n" .
                                           '    if (function_exists("' . $funcName . '")) { $html = $html . ' . $functionCall . '; }' . "\n" .
                                           '    $html = $html . \'</select></td>\';';
                            $content = substr($content, 0, $tagClosePos) . $replacement . substr($content, $tdClosePos);
                            return true;
                        }
                    }
                }
                $offset = $pos + strlen($needle);
            }
            return false;
        }

        patch_select_block($c, 'wday_start', 'issabel_draw_wday_options($wday_start)');
        patch_select_block($c, 'wday_finish', 'issabel_draw_wday_options($wday_finish)');
        patch_select_block($c, 'month_start', 'issabel_draw_month_options($month_start)');
        patch_select_block($c, 'month_finish', 'issabel_draw_month_options($month_finish)');

        // Validate syntax before writing
        $phpBin = defined('PHP_BINARY') && PHP_BINARY ? PHP_BINARY : 'php';
        $tmp = tempnam(sys_get_temp_dir(), 'tg_check_');
        file_put_contents($tmp, $c);
        $lint = shell_exec(escapeshellcmd($phpBin) . ' -l ' . escapeshellarg($tmp) . ' 2>&1');
        @unlink($tmp);

        if (strpos($lint, 'No syntax errors') !== false) {
            file_put_contents($tcFuncs, $c);
            echo "functions.inc.php patched successfully.\n";
        } else {
            echo "Lint error, keeping backup: $lint\n";
        }
    }
}

// Patch page.timegroups.php for Shamsi live server date badge
if (file_exists($tcPage)) {
    $c = file_get_contents($tcPage);
    if (strpos($c, 'issabel-persian-shamsi-time') === false && strpos($c, 'id="idTime"') !== false) {
        $bak = $tcPage . '.bak_' . date('Ymd_His');
        copy($tcPage, $bak);

        $shamsiBadge = '<span id="idTime">00:00:00</span>' .
            '<?php if (function_exists("issabel_jdate")) { ?>' .
            ' <span class="issabel-persian-shamsi-time" style="margin-left: 10px; margin-right: 10px; color: #1a73e8; background: #e8f0fe; padding: 2px 8px; border-radius: 4px; font-size: 12px; font-weight: bold;">' .
            '📅 <?php echo issabel_jdate("l j F Y"); ?>' .
            '</span><?php } ?>';
        $c = str_replace('<span id="idTime">00:00:00</span>', $shamsiBadge, $c);

        $phpBin = defined('PHP_BINARY') && PHP_BINARY ? PHP_BINARY : 'php';
        $tmp = tempnam(sys_get_temp_dir(), 'tg_page_check_');
        file_put_contents($tmp, $c);
        $lint = shell_exec(escapeshellcmd($phpBin) . ' -l ' . escapeshellarg($tmp) . ' 2>&1');
        @unlink($tmp);

        if (strpos($lint, 'No syntax errors') !== false) {
            file_put_contents($tcPage, $c);
            echo "page.timegroups.php patched successfully.\n";
        }
    }
}
