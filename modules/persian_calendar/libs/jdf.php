<?php
/**
 * Jalali Date Functions for Issabel PBX
 * Compatible with PHP 5.4+ up to PHP 8.x
 */

if (!function_exists('issabel_gregorian_to_jalali')) {
    function issabel_gregorian_to_jalali($gy, $gm, $gd) {
        $g_d_m = array(0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334);
        if ($gy > 1600) {
            $jy = 979;
            $gy -= 1600;
        } else {
            $jy = 0;
            $gy -= 621;
        }
        $gy2 = ($gm > 2) ? ($gy + 1) : $gy;
        $days = (365 * $gy) + ((int)(($gy2 + 3) / 4)) - ((int)(($gy2 + 99) / 100)) + ((int)(($gy2 + 399) / 400)) - 80 + $gd + $g_d_m[$gm - 1];
        $jy += 33 * ((int)($days / 12053));
        $days %= 12053;
        $jy += 4 * ((int)($days / 1461));
        $days %= 1461;
        if ($days > 365) {
            $jy += (int)(($days - 1) / 365);
            $days = ($days - 1) % 365;
        }
        $jm = ($days < 186) ? 1 + (int)($days / 31) : 7 + (int)(($days - 186) / 30);
        $jd = 1 + (($days < 186) ? ($days % 31) : (($days - 186) % 30));
        return array($jy, $jm, $jd);
    }
}

if (!function_exists('issabel_jalali_to_gregorian')) {
    function issabel_jalali_to_gregorian($jy, $jm, $jd) {
        if ($jy > 979) {
            $gy = 1600;
            $jy -= 979;
        } else {
            $gy = 621;
        }
        $days = (365 * $jy) + (((int)($jy / 33)) * 8) + ((int)((($jy % 33) + 3) / 4)) + 78 + $jd + (($jm < 7) ? ($jm - 1) * 31 : (($jm - 7) * 30) + 186);
        $gy += 400 * ((int)($days / 146097));
        $days %= 146097;
        if ($days > 36524) {
            $gy += 100 * ((int)(--$days / 36524));
            $days %= 36524;
            if ($days >= 365) $days++;
        }
        $gy += 4 * ((int)($days / 1461));
        $days %= 1461;
        if ($days > 365) {
            $gy += (int)(($days - 1) / 365);
            $days = ($days - 1) % 365;
        }
        $sal_a = array(0, 31, (($gy % 4 == 0 && $gy % 100 != 0) || ($gy % 400 == 0)) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
        for ($gm = 0; $gm < 13 && $days >= $sal_a[$gm]; $gm++) {
            $days -= $sal_a[$gm];
        }
        $gd = $days + 1;
        return array($gy, $gm, $gd);
    }
}

if (!function_exists('issabel_is_leap_jalali')) {
    function issabel_is_leap_jalali($jy) {
        $g = issabel_jalali_to_gregorian($jy, 12, 30);
        $j = issabel_gregorian_to_jalali($g[0], $g[1], $g[2]);
        return ($j[0] == $jy && $j[1] == 12 && $j[2] == 30);
    }
}

if (!function_exists('issabel_jalali_month_days')) {
    function issabel_jalali_month_days($jy, $jm) {
        if ($jm >= 1 && $jm <= 6) return 31;
        if ($jm >= 7 && $jm <= 11) return 30;
        if ($jm == 12) return issabel_is_leap_jalali($jy) ? 30 : 29;
        return 30;
    }
}

if (!function_exists('issabel_persian_digits')) {
    function issabel_persian_digits($str) {
        $fa = array('۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹');
        $en = array('0', '1', '2', '3', '4', '5', '6', '7', '8', '9');
        return str_replace($en, $fa, (string)$str);
    }
}

if (!function_exists('issabel_latin_digits')) {
    function issabel_latin_digits($str) {
        $fa = array('۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹', '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩');
        $en = array('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9');
        return str_replace($fa, $en, (string)$str);
    }
}

if (!function_exists('issabel_jdate')) {
    function issabel_jdate($format, $timestamp = null, $persian_digits = false) {
        if ($timestamp === null || $timestamp === '') {
            $timestamp = time();
        } elseif (!is_numeric($timestamp)) {
            $timestamp = strtotime($timestamp);
        }

        if (!$timestamp) {
            $timestamp = time();
        }

        $date_parts = explode('_', date('Y_m_d_H_i_s_w', $timestamp));
        $gy = (int)$date_parts[0];
        $gm = (int)$date_parts[1];
        $gd = (int)$date_parts[2];
        $h  = $date_parts[3];
        $i  = $date_parts[4];
        $s  = $date_parts[5];
        $gw = (int)$date_parts[6]; // 0 (Sun) to 6 (Sat)

        list($jy, $jm, $jd) = issabel_gregorian_to_jalali($gy, $gm, $gd);

        // Persian day of week: Saturday is 0
        $jw = ($gw + 1) % 7;

        $month_names = array(
            1  => 'فروردین',
            2  => 'اردیبهشت',
            3  => 'خرداد',
            4  => 'تیر',
            5  => 'مرداد',
            6  => 'شهریور',
            7  => 'مهر',
            8  => 'آبان',
            9  => 'آذر',
            10 => 'دی',
            11 => 'بهمن',
            12 => 'اسفند'
        );

        $day_names = array(
            0 => 'شنبه',
            1 => 'یکشنبه',
            2 => 'دوشنبه',
            3 => 'سه‌شنبه',
            4 => 'چهارشنبه',
            5 => 'پنج‌شنبه',
            6 => 'جمعه'
        );

        $replace = array(
            'Y' => sprintf('%04d', $jy),
            'y' => sprintf('%02d', $jy % 100),
            'm' => sprintf('%02d', $jm),
            'n' => $jm,
            'd' => sprintf('%02d', $jd),
            'j' => $jd,
            'F' => $month_names[$jm],
            'M' => $month_names[$jm],
            'l' => $day_names[$jw],
            'D' => mb_substr($day_names[$jw], 0, 1, 'UTF-8'),
            'H' => $h,
            'h' => sprintf('%02d', ($h % 12 == 0 ? 12 : $h % 12)),
            'i' => $i,
            's' => $s,
            'A' => ($h < 12 ? 'قبل از ظهر' : 'بعد از ظهر'),
            'a' => ($h < 12 ? 'ق.ظ' : 'ب.ظ')
        );

        $out = '';
        $len = strlen($format);
        for ($k = 0; $k < $len; $k++) {
            $char = $format[$k];
            if (isset($replace[$char])) {
                $out .= $replace[$char];
            } else {
                $out .= $char;
            }
        }

        if ($persian_digits) {
            return issabel_persian_digits($out);
        }

        return $out;
    }
}
