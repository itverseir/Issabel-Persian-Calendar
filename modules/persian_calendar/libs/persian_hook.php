<?php
/**
 * Global Core Hook for Issabel PBX Persian Calendar
 * Intercepts incoming requests and transparently translates Shamsi dates into Gregorian
 * for database queries (CDR, Recordings, Queues, System Logs, etc.).
 * 
 * Developed by: Amir Safari - ITVERSE.IR
 * Copyright (c) 2024-2026 Amir Safari - ITVERSE.IR. All rights reserved.
 * مالکیت مادی و معنوی: امیر صفری - ITVERSE.IR
 */

if (defined('ISSABEL_PERSIAN_HOOK_LOADED')) {
    return;
}
define('ISSABEL_PERSIAN_HOOK_LOADED', true);

require_once __DIR__ . '/jdf.php';

class IssabelPersianHook {
    private static $config = null;
    private static $configFile = null;

    public static function init() {
        self::$configFile = __DIR__ . '/../configs/config.json';
        self::loadConfig();

        if (!empty(self::$config['enabled']) && !empty(self::$config['convert_backend_requests'])) {
            self::processGlobalRequests();
        }
    }

    public static function loadConfig() {
        if (file_exists(self::$configFile)) {
            $data = file_get_contents(self::$configFile);
            self::$config = json_decode($data, true);
        }

        if (!is_array(self::$config)) {
            self::$config = array(
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
    }

    public static function getConfig() {
        if (self::$config === null) {
            self::loadConfig();
        }
        return self::$config;
    }

    /**
     * Recursively convert Jalali dates found in $_GET, $_POST, $_REQUEST to Gregorian
     */
    private static function processGlobalRequests() {
        if (!empty($_GET)) {
            $_GET = self::convertArrayDates($_GET);
        }
        if (!empty($_POST)) {
            $_POST = self::convertArrayDates($_POST);
        }
        if (!empty($_REQUEST)) {
            $_REQUEST = self::convertArrayDates($_REQUEST);
        }
    }

    public static function convertArrayDates($data) {
        if (!is_array($data)) {
            return self::convertStringDate($data);
        }

        foreach ($data as $key => $value) {
            if (is_array($value)) {
                $data[$key] = self::convertArrayDates($value);
            } else {
                $data[$key] = self::convertStringDate($value);
            }
        }
        return $data;
    }

    /**
     * Check if a string matches Jalali date pattern (1300-1499) and convert to Gregorian
     */
    public static function convertStringDate($str) {
        if (!is_string($str) || strlen($str) < 8 || strlen($str) > 40) {
            return $str;
        }

        // Normalize Persian/Arabic digits to Latin
        $latinStr = issabel_latin_digits(trim($str));

        $monthsEn = array(
            1=>'Jan', 2=>'Feb', 3=>'Mar', 4=>'Apr', 5=>'May', 6=>'Jun',
            7=>'Jul', 8=>'Aug', 9=>'Sep', 10=>'Oct', 11=>'Nov', 12=>'Dec'
        );

        // Pattern 1: YYYY-MM-DD or YYYY/MM/DD
        if (preg_match('/^(1[34]\d{2})[-\/](0?[1-9]|1[0-2])[-\/](0?[1-9]|[12]\d|3[01])$/', $latinStr, $matches)) {
            $jy = (int)$matches[1];
            $jm = (int)$matches[2];
            $jd = (int)$matches[3];
            list($gy, $gm, $gd) = issabel_jalali_to_gregorian($jy, $jm, $jd);
            // Format as "d M Y" (e.g. "15 Oct 2026") which is the native format for all Issabel form validators
            return sprintf('%02d %s %04d', $gd, $monthsEn[$gm], $gy);
        }

        // Pattern 2: YYYY-MM-DD HH:MM:SS or YYYY/MM/DD HH:MM:SS
        if (preg_match('/^(1[34]\d{2})[-\/](0?[1-9]|1[0-2])[-\/](0?[1-9]|[12]\d|3[01])\s+([01]?\d|2[0-3]):([0-5]\d)(:([0-5]\d))?$/', $latinStr, $matches)) {
            $jy = (int)$matches[1];
            $jm = (int)$matches[2];
            $jd = (int)$matches[3];
            $hour = (int)$matches[4];
            $min  = (int)$matches[5];
            $sec  = isset($matches[7]) ? (int)$matches[7] : 0;
            list($gy, $gm, $gd) = issabel_jalali_to_gregorian($jy, $jm, $jd);
            return sprintf('%04d-%02d-%02d %02d:%02d:%02d', $gy, $gm, $gd, $hour, $min, $sec);
        }

        // Pattern 3: DD-MM-YYYY or DD/MM/YYYY with Jalali year
        if (preg_match('/^(0?[1-9]|[12]\d|3[01])[-\/](0?[1-9]|1[0-2])[-\/](1[34]\d{2})$/', $latinStr, $matches)) {
            $jd = (int)$matches[1];
            $jm = (int)$matches[2];
            $jy = (int)$matches[3];
            list($gy, $gm, $gd) = issabel_jalali_to_gregorian($jy, $jm, $jd);
            return sprintf('%02d %s %04d', $gd, $monthsEn[$gm], $gy);
        }

        return $str;
    }
}

// Global helper functions
if (!function_exists('issabel_to_shamsi')) {
    function issabel_to_shamsi($datetime, $format = 'Y/m/d H:i:s', $persian_digits = null) {
        if ($persian_digits === null) {
            $cfg = IssabelPersianHook::getConfig();
            $persian_digits = (isset($cfg['digits']) && $cfg['digits'] === 'fa');
        }
        return issabel_jdate($format, $datetime, $persian_digits);
    }
}

if (!function_exists('issabel_to_gregorian')) {
    function issabel_to_gregorian($jalali_str) {
        return IssabelPersianHook::convertStringDate($jalali_str);
    }
}

// Automatically execute hook
IssabelPersianHook::init();
