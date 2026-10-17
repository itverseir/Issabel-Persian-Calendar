<?php
/**
 * Issabel PBX - Persian Calendar Module Backend Class
 * Developed by: Amir Safari - ITVERSE.IR
 * Copyright (c) 2024-2026 Amir Safari - ITVERSE.IR. All rights reserved.
 * مالکیت مادی و معنوی: امیر صفری - ITVERSE.IR
 */

class paloSantoPersianCalendar {
    private $configFile;
    private $webPath;

    public function __construct() {
        $this->configFile = __DIR__ . '/../configs/config.json';
        $this->webPath = dirname(dirname(dirname(__DIR__))); // /var/www/html
    }

    public function getConfig() {
        if (file_exists($this->configFile)) {
            $data = file_get_contents($this->configFile);
            $cfg = json_decode($data, true);
            if (is_array($cfg)) {
                return $cfg;
            }
        }

        return array(
            'enabled'                   => true,
            'datepicker_enabled'        => true,
            'table_dates_enabled'       => true,
            'header_clock_enabled'      => true,
            'date_format'               => 'YYYY/MM/DD',
            'digits'                    => 'fa',
            'show_gregorian_tooltip'    => true,
            'convert_backend_requests'  => true,
            'show_day_of_week'          => true,
            'time_format'               => '24h'
        );
    }

    public function saveConfig($newConfig) {
        $current = $this->getConfig();
        $merged = array_merge($current, $newConfig);
        $json = json_encode($merged, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        $res = file_put_contents($this->configFile, $json) !== false;

        $jsFile = dirname(__DIR__) . '/assets/js/config.js';
        @file_put_contents($jsFile, "window.ISSABEL_PERSIAN_CONFIG = " . $json . ";\n");
        return $res;
    }

    public function getSystemStatus() {
        $status = array(
            'hook_index'    => false,
            'theme_tenant'  => false,
            'theme_neo'     => false,
            'config_writable' => is_writable($this->configFile) || is_writable(dirname($this->configFile)),
            'php_version'   => PHP_VERSION,
            'sqlite_active' => extension_loaded('sqlite3') || extension_loaded('pdo_sqlite'),
        );

        // Check index.php hook
        $indexFile = $this->webPath . '/index.php';
        if (file_exists($indexFile)) {
            $content = file_get_contents($indexFile);
            if (strpos($content, 'persian_hook.php') !== false) {
                $status['hook_index'] = true;
            }
        }

        // Check tenant theme
        $tenantFiles = array(
            $this->webPath . '/themes/tenant/_common/index.tpl',
            $this->webPath . '/themes/tenant/_common/_menu.tpl'
        );
        foreach ($tenantFiles as $tf) {
            if (file_exists($tf) && strpos(file_get_contents($tf), 'issabel-persian.js') !== false) {
                $status['theme_tenant'] = true;
                break;
            }
        }

        // Check farsi_rtl theme
        $farsiFiles = array(
            $this->webPath . '/themes/farsi_rtl/_common/index.tpl',
            $this->webPath . '/themes/farsi_rtl/_common/_menu.tpl'
        );
        foreach ($farsiFiles as $ff) {
            if (file_exists($ff) && strpos(file_get_contents($ff), 'issabel-persian.js') !== false) {
                $status['theme_farsi'] = true;
                break;
            }
        }

        // Check elastixneo theme
        $neoTpl = $this->webPath . '/themes/elastixneo/_common/index.tpl';
        if (file_exists($neoTpl)) {
            $content = file_get_contents($neoTpl);
            if (strpos($content, 'issabel-persian.js') !== false) {
                $status['theme_neo'] = true;
            }
        }

        return $status;
    }

    public function applyHooks() {
        $results = array();

        // 1. Hook index.php
        $indexFile = $this->webPath . '/index.php';
        if (file_exists($indexFile) && is_writable($indexFile)) {
            $content = file_get_contents($indexFile);
            if (strpos($content, 'persian_hook.php') === false) {
                $hookCode = "\n// START ISSABEL PERSIAN CALENDAR HOOK\n" .
                            "if (file_exists(__DIR__ . '/modules/persian_calendar/libs/persian_hook.php')) {\n" .
                            "    require_once __DIR__ . '/modules/persian_calendar/libs/persian_hook.php';\n" .
                            "}\n" .
                            "// END ISSABEL PERSIAN CALENDAR HOOK\n";
                $newContent = preg_replace('/^<\?php/i', "<?php" . $hookCode, $content, 1);
                if ($newContent && $newContent !== $content) {
                    file_put_contents($indexFile, $newContent);
                    $results['index.php'] = 'patched';
                }
            } else {
                $results['index.php'] = 'already_patched';
            }
        }

        // 2. Hook theme templates
        $themeFiles = array(
            $this->webPath . '/themes/tenant/_common/index.tpl',
            $this->webPath . '/themes/farsi_rtl/_common/index.tpl',
            $this->webPath . '/themes/elastixneo/_common/index.tpl'
        );

        $tagInject = "\n<!-- START ISSABEL PERSIAN CALENDAR -->\n" .
                     "<link rel=\"stylesheet\" type=\"text/css\" href=\"modules/persian_calendar/assets/css/persian-datepicker.css\" />\n" .
                     "<link rel=\"stylesheet\" type=\"text/css\" href=\"modules/persian_calendar/assets/css/issabel-persian.css\" />\n" .
                     "<script type=\"text/javascript\" src=\"modules/persian_calendar/assets/js/issabel-persian.js\"></script>\n" .
                     "<!-- END ISSABEL PERSIAN CALENDAR -->\n";

        foreach ($themeFiles as $file) {
            if (file_exists($file) && is_writable($file)) {
                $content = file_get_contents($file);
                if (strpos($content, 'issabel-persian.js') === false) {
                    if (strpos($content, '</head>') !== false) {
                        $newContent = str_replace('</head>', $tagInject . '</head>', $content);
                    } else {
                        $newContent = $content . $tagInject;
                    }
                    file_put_contents($file, $newContent);
                    $results[basename(dirname(dirname($file)))] = 'patched';
                } else {
                    $results[basename(dirname(dirname($file)))] = 'already_patched';
                }
            }
        }

        return $results;
    }
}
