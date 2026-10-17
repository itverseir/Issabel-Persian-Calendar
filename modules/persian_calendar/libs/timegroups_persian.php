<?php
/**
 * Issabel PBX - Persian Calendar Engine for Time Groups & Time Conditions
 * Translates Shamsi time definitions (weekdays, days of month, Shamsi months)
 * into native Asterisk GotoIfTime dialplan rules.
 */

if (defined('ISSABEL_TIMEGROUPS_PERSIAN_LOADED')) {
    return;
}
define('ISSABEL_TIMEGROUPS_PERSIAN_LOADED', true);

$jdf_path = __DIR__ . '/jdf.php';
if (file_exists($jdf_path)) {
    require_once $jdf_path;
}

global $issabel_shamsi_months, $issabel_shamsi_weekdays, $issabel_greg_months;

$issabel_shamsi_months = array(
    'far' => array('id' => 1,  'name' => 'فروردین', 'days' => 31),
    'ord' => array('id' => 2,  'name' => 'اردیبهشت', 'days' => 31),
    'kho' => array('id' => 3,  'name' => 'خرداد',    'days' => 31),
    'tir' => array('id' => 4,  'name' => 'تیر',      'days' => 31),
    'mor' => array('id' => 5,  'name' => 'مرداد',    'days' => 31),
    'sha' => array('id' => 6,  'name' => 'شهریور',   'days' => 31),
    'meh' => array('id' => 7,  'name' => 'مهر',      'days' => 30),
    'aba' => array('id' => 8,  'name' => 'آبان',     'days' => 30),
    'aza' => array('id' => 9,  'name' => 'آذر',      'days' => 30),
    'dey' => array('id' => 10, 'name' => 'دی',       'days' => 30),
    'bah' => array('id' => 11, 'name' => 'بهمن',     'days' => 30),
    'esf' => array('id' => 12, 'name' => 'اسفند',    'days' => 29)
);

$issabel_shamsi_weekdays = array(
    'sat' => 'شنبه (Saturday)',
    'sun' => 'یکشنبه (Sunday)',
    'mon' => 'دوشنبه (Monday)',
    'tue' => 'سه‌شنبه (Tuesday)',
    'wed' => 'چهارشنبه (Wednesday)',
    'thu' => 'پنج‌شنبه (Thursday)',
    'fri' => 'جمعه (Friday)'
);

$issabel_greg_months = array(
    1 => 'jan', 2 => 'feb', 3 => 'mar', 4 => 'apr', 5 => 'may', 6 => 'jun',
    7 => 'jul', 8 => 'aug', 9 => 'sep', 10 => 'oct', 11 => 'nov', 12 => 'dec'
);

function issabel_is_shamsi_month_code($code) {
    global $issabel_shamsi_months;
    return isset($issabel_shamsi_months[$code]);
}

function issabel_get_greg_month_days($gy, $gm) {
    if ($gm == 2) {
        $leap = (($gy % 4 === 0 && $gy % 100 !== 0) || ($gy % 400 === 0));
        return $leap ? 29 : 28;
    }
    $sal = array(0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    return $sal[$gm];
}

/**
 * Converts a Shamsi month/day interval into standard Asterisk GotoIfTime (mday, month) expressions
 */
function issabel_convert_shamsi_to_asterisk_rules($jm_start, $jd_start, $jm_finish, $jd_finish) {
    global $issabel_greg_months;

    list($jy_now) = function_exists('issabel_gregorian_to_jalali')
        ? issabel_gregorian_to_jalali((int)date('Y'), (int)date('m'), (int)date('d'))
        : array(1405);

    if ($jd_start == '-' || $jd_start == '*' || !$jd_start) {
        $jd_start = 1;
    }
    if ($jd_finish == '-' || $jd_finish == '*' || !$jd_finish) {
        $jd_finish = ($jm_finish <= 6) ? 31 : (($jm_finish <= 11) ? 30 : 29);
    }

    if (function_exists('issabel_jalali_to_gregorian')) {
        list($gy_s, $gm_s, $gd_s) = issabel_jalali_to_gregorian($jy_now, $jm_start, $jd_start);
        list($gy_f, $gm_f, $gd_f) = issabel_jalali_to_gregorian($jy_now, $jm_finish, $jd_finish);
    } else {
        return array(array('mday' => '*', 'month' => '*'));
    }

    $rules = array();

    // 1. Single Gregorian month
    if ($gm_s == $gm_f && $gy_s == $gy_f) {
        $mday = ($gd_s == $gd_f) ? $gd_s : "$gd_s-$gd_f";
        $rules[] = array('mday' => $mday, 'month' => $issabel_greg_months[$gm_s]);
        return $rules;
    }

    // 2. First month trailing days: gd_s to end of month
    $endOfFirst = issabel_get_greg_month_days($gy_s, $gm_s);
    $mdayFirst = ($gd_s == $endOfFirst) ? $gd_s : "$gd_s-$endOfFirst";
    $rules[] = array('mday' => $mdayFirst, 'month' => $issabel_greg_months[$gm_s]);

    // 3. Intermediate full months
    $curr_y = $gy_s;
    $curr_m = $gm_s + 1;
    if ($curr_m > 12) { $curr_m = 1; $curr_y++; }

    $fullMonths = array();
    while ($curr_y < $gy_f || ($curr_y == $gy_f && $curr_m < $gm_f)) {
        $fullMonths[] = $curr_m;
        $curr_m++;
        if ($curr_m > 12) { $curr_m = 1; $curr_y++; }
    }

    if (!empty($fullMonths)) {
        if (count($fullMonths) == 1) {
            $rules[] = array('mday' => '*', 'month' => $issabel_greg_months[$fullMonths[0]]);
        } else {
            $firstM = $issabel_greg_months[$fullMonths[0]];
            $lastM  = $issabel_greg_months[$fullMonths[count($fullMonths) - 1]];
            $rules[] = array('mday' => '*', 'month' => "$firstM-$lastM");
        }
    }

    // 4. Last month leading days: 1 to gd_f
    $mdayLast = ($gd_f == 1) ? "1" : "1-$gd_f";
    $rules[] = array('mday' => $mdayLast, 'month' => $issabel_greg_months[$gm_f]);

    return $rules;
}

/**
 * Expands any time string that uses Shamsi months into valid Asterisk GotoIfTime strings
 * Format: <hour_interval>|<wday_interval>|<mday_interval>|<month_interval>
 */
function issabel_expand_shamsi_time_rule($time_string) {
    global $issabel_shamsi_months;

    $parts = explode('|', $time_string);
    if (count($parts) < 4) {
        return array($time_string);
    }

    $time_hour  = $parts[0];
    $time_wday  = $parts[1];
    $time_mday  = $parts[2];
    $time_month = $parts[3];

    // Check if month contains Shamsi codes
    $monthParts = explode('-', $time_month);
    $mStart = $monthParts[0];
    $mFinish = isset($monthParts[1]) ? $monthParts[1] : $mStart;

    if (!issabel_is_shamsi_month_code($mStart) && !issabel_is_shamsi_month_code($mFinish)) {
        // Not a Shamsi month rule, return as is
        return array($time_string);
    }

    $jm_start = issabel_is_shamsi_month_code($mStart) ? $issabel_shamsi_months[$mStart]['id'] : 1;
    $jm_finish = issabel_is_shamsi_month_code($mFinish) ? $issabel_shamsi_months[$mFinish]['id'] : $jm_start;

    $mdayParts = explode('-', $time_mday);
    $dStart = $mdayParts[0];
    $dFinish = isset($mdayParts[1]) ? $mdayParts[1] : $dStart;

    $converted = issabel_convert_shamsi_to_asterisk_rules($jm_start, $dStart, $jm_finish, $dFinish);
    $expanded = array();
    foreach ($converted as $c) {
        $expanded[] = $time_hour . '|' . $time_wday . '|' . $c['mday'] . '|' . $c['month'];
    }

    return $expanded;
}

function issabel_draw_wday_options($selected) {
    global $issabel_shamsi_weekdays;
    $default = ($selected == '-') ? ' selected' : '';
    $out = "<option value=\"-\" $default>-";
    foreach ($issabel_shamsi_weekdays as $code => $label) {
        $sel = ($selected == $code) ? ' selected' : '';
        $out .= "<option value=\"$code\" $sel>$label";
    }
    return $out;
}

function issabel_draw_month_options($selected) {
    global $issabel_shamsi_months;
    $gregMonths = array(
        'jan' => 'ژانویه (January)',
        'feb' => 'فوریه (February)',
        'mar' => 'مارس (March)',
        'apr' => 'آوریل (April)',
        'may' => 'مه (May)',
        'jun' => 'ژوئن (June)',
        'jul' => 'ژوئیه (July)',
        'aug' => 'اوت (August)',
        'sep' => 'سپتامبر (September)',
        'oct' => 'اکتبر (October)',
        'nov' => 'نوامبر (November)',
        'dec' => 'دسامبر (December)'
    );

    $default = ($selected == '-') ? ' selected' : '';
    $out = "<option value=\"-\" $default>-";
    $out .= "<optgroup label=\"ماه‌های شمسی (جلالی)\">";
    foreach ($issabel_shamsi_months as $code => $info) {
        $sel = ($selected == $code) ? ' selected' : '';
        $out .= "<option value=\"$code\" $sel>{$info['name']}";
    }
    $out .= "</optgroup>";
    $out .= "<optgroup label=\"ماه‌های میلادی (Gregorian)\">";
    foreach ($gregMonths as $code => $label) {
        $sel = ($selected == $code) ? ' selected' : '';
        $out .= "<option value=\"$code\" $sel>$label";
    }
    $out .= "</optgroup>";
    return $out;
}

/**
 * Formatted current Shamsi date and day of week
 */
function issabel_get_shamsi_now_string() {
    if (function_exists('issabel_jdate')) {
        return issabel_jdate('l، j F Y');
    }
    return date('Y-m-d');
}
