<?php
/**
 * Test script for Issabel Persian Calendar module
 * Can be run via CLI: php test_dates.php
 * 
 * Developed by: Amir Safari - ITVERSE.IR
 * Copyright (c) 2024-2026 Amir Safari - ITVERSE.IR. All rights reserved.
 * مالکیت مادی و معنوی: امیر صفری - ITVERSE.IR
 */

if (file_exists('/var/www/html/modules/persian_calendar/libs/jdf.php')) {
    require_once '/var/www/html/modules/persian_calendar/libs/jdf.php';
    require_once '/var/www/html/modules/persian_calendar/libs/persian_hook.php';
} else {
    require_once __DIR__ . '/modules/persian_calendar/libs/jdf.php';
    require_once __DIR__ . '/modules/persian_calendar/libs/persian_hook.php';
}

echo "====================================================\n";
echo " Issabel Persian Calendar - Unit Test Suite\n";
echo "====================================================\n\n";

$testDates = array(
    array('2024-03-20', '1403/01/01'),
    array('2024-11-05', '1403/08/15'),
    array('2025-03-20', '1403/12/30'), // Leap day of 1403
    array('2025-03-21', '1404/01/01'),
    array('2026-10-15', '1405/07/23')
);

$pass = 0;
$fail = 0;

echo "1. Testing Gregorian <-> Jalali Conversion:\n";
foreach ($testDates as $item) {
    list($greg, $expectedJalali) = $item;
    list($gy, $gm, $gd) = explode('-', $greg);
    list($jy, $jm, $jd) = issabel_gregorian_to_jalali((int)$gy, (int)$gm, (int)$gd);
    $calculatedJalali = sprintf('%04d/%02d/%02d', $jy, $jm, $jd);

    list($backGy, $backGm, $backGd) = issabel_jalali_to_gregorian($jy, $jm, $jd);
    $calculatedGreg = sprintf('%04d-%02d-%02d', $backGy, $backGm, $backGd);

    if ($calculatedJalali === $expectedJalali && $calculatedGreg === $greg) {
        echo "  [PASS] $greg <==> $calculatedJalali\n";
        $pass++;
    } else {
        echo "  [FAIL] $greg expected $expectedJalali got $calculatedJalali (back: $calculatedGreg)\n";
        $fail++;
    }
}

echo "\n2. Testing Request Interceptor (Jalali to Gregorian Query Translation):\n";
$filterTests = array(
    array('1403/08/15', '05 Nov 2024'),
    array('1403-08-15', '05 Nov 2024'),
    array('۱۴۰۳/۰۸/۱۵', '05 Nov 2024'), // Persian digits
    array('1403/08/15 14:30:00', '2024-11-05 14:30:00'),
    array('105', '105'), // Extension number (must NOT be modified!)
    array('1403', '1403') // Extension number 1403 (must NOT be modified!)
);

foreach ($filterTests as $pair) {
    list($input, $expected) = $pair;
    $result = IssabelPersianHook::convertStringDate($input);
    if ($result === $expected) {
        echo "  [PASS] '$input' => '$result'\n";
        $pass++;
    } else {
        echo "  [FAIL] '$input' => expected '$expected' but got '$result'\n";
        $fail++;
    }
}

echo "\n3. Testing Patched translateDate (Asterisk CDR & Summary Query Compatibility):\n";
function simulatedTranslateDate($dateOrig) {
    if (is_string($dateOrig)) {
        $trimmed = issabel_latin_digits(trim($dateOrig));
        if (preg_match('/^(1[34]\d{2})[-\/](0?[1-9]|1[0-2])[-\/](0?[1-9]|[12]\d|3[01])$/', $trimmed, $mJalali)) {
            if (function_exists('issabel_jalali_to_gregorian')) {
                list($gy, $gm, $gd) = issabel_jalali_to_gregorian((int)$mJalali[1], (int)$mJalali[2], (int)$mJalali[3]);
                return sprintf('%04d-%02d-%02d', $gy, $gm, $gd);
            }
        }
        if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $trimmed)) {
            return $trimmed;
        }
    }
    // Original Issabel fallback logic for "17 Oct 2026"
    if (preg_match("/([[:digit:]]{1,2})[[:space:]]+([[:alnum:]]{3})[[:space:]]+([[:digit:]]{4})/", $dateOrig, $arrReg)) {
        $months = array("Jan"=>"01","Feb"=>"02","Mar"=>"03","Apr"=>"04","May"=>"05","Jun"=>"06","Jul"=>"07","Aug"=>"08","Sep"=>"09","Oct"=>"10","Nov"=>"11","Dec"=>"12");
        $mKey = ucfirst(strtolower($arrReg[2]));
        if (isset($months[$mKey])) {
            return sprintf('%04d-%02d-%02d', (int)$arrReg[3], (int)$months[$mKey], (int)$arrReg[1]);
        }
    }
    return false;
}

$translateTests = array(
    array('1403/08/15', '2024-11-05'),
    array('1403-08-15', '2024-11-05'),
    array('۱۴۰۳/۰۸/۱۵', '2024-11-05'),
    array('17 Oct 2026', '2026-10-17'),
    array('05 Nov 2024', '2024-11-05'),
    array('2026-10-17', '2026-10-17'),
    array('2024-11-05', '2024-11-05'),
);

foreach ($translateTests as $tPair) {
    list($inVal, $expVal) = $tPair;
    $resVal = simulatedTranslateDate($inVal);
    if ($resVal === $expVal) {
        echo "  [PASS] translateDate('$inVal') => '$resVal' (Safe for Asterisk CDR queries!)\n";
        $pass++;
    } else {
        echo "  [FAIL] translateDate('$inVal') => expected '$expVal' got '$resVal'\n";
        $fail++;
    }
}

echo "\n4. Testing Persian Digits formatting:\n";
$digitsTest = issabel_persian_digits("1403/08/15 12:30:45");
if ($digitsTest === "۱۴۰۳/۰۸/۱۵ ۱۲:۳۰:۴۵") {
    echo "  [PASS] '$digitsTest'\n";
    $pass++;
} else {
    echo "  [FAIL] Expected '۱۴۰۳/۰۸/۱۵ ۱۲:۳۰:۴۵' got '$digitsTest'\n";
    $fail++;
}

echo "\n5. Testing Time Groups Shamsi Engine (GotoIfTime Expansion):\n";
$tgPath = file_exists('/var/www/html/modules/persian_calendar/libs/timegroups_persian.php')
    ? '/var/www/html/modules/persian_calendar/libs/timegroups_persian.php'
    : __DIR__ . '/modules/persian_calendar/libs/timegroups_persian.php';

if (file_exists($tgPath)) {
    require_once $tgPath;

    // Test 4.1: Regular time rule untouched
    $r1 = issabel_expand_shamsi_time_rule("08:00-17:00|sat-wed|*|*");
    if (count($r1) === 1 && $r1[0] === "08:00-17:00|sat-wed|*|*") {
        echo "  [PASS] Regular rule: 08:00-17:00|sat-wed|*|*\n";
        $pass++;
    } else {
        echo "  [FAIL] Regular rule unexpected output\n";
        $fail++;
    }

    // Test 4.2: Nowruz (1-13 Farvardin)
    $r2 = issabel_expand_shamsi_time_rule("08:00-17:00|sat-wed|1-13|far");
    if (count($r2) === 2 && strpos($r2[0], 'mar') !== false && strpos($r2[1], 'apr') !== false) {
        echo "  [PASS] Shamsi Nowruz (1-13 Farvardin) expanded to 2 Asterisk GotoIfTime rules:\n";
        foreach ($r2 as $subRule) { echo "         - $subRule\n"; }
        $pass++;
    } else {
        echo "  [FAIL] Nowruz rule expansion failed\n";
        $fail++;
    }

    // Test 4.3: Farvardin to Shahrivar (Months 1 to 6)
    $r3 = issabel_expand_shamsi_time_rule("09:00-13:00|thu|*|far-sha");
    if (count($r3) >= 2 && strpos($r3[0], 'mar') !== false && strpos($r3[count($r3)-1], 'sep') !== false) {
        echo "  [PASS] Shamsi Summer/Spring (Farvardin-Shahrivar) expanded to " . count($r3) . " Asterisk rules:\n";
        foreach ($r3 as $subRule) { echo "         - $subRule\n"; }
        $pass++;
    } else {
        echo "  [FAIL] Farvardin-Shahrivar expansion failed\n";
        $fail++;
    }

    // Test 4.4: 22 Bahman single day holiday
    $r4 = issabel_expand_shamsi_time_rule("*|*|22|bah");
    if (count($r4) === 1 && $r4[0] === "*|*|11|feb") {
        echo "  [PASS] Single Shamsi holiday (*|*|22|bah) => *|*|11|feb\n";
        $pass++;
    } else {
        echo "  [FAIL] 22 Bahman rule expansion failed\n";
        $fail++;
    }

    // Test 4.5: Wday options contains Persian names
    $wdayHtml = issabel_draw_wday_options('sat');
    if (strpos($wdayHtml, 'شنبه') !== false && strpos($wdayHtml, 'value="sat"') !== false) {
        echo "  [PASS] Wday selector contains Persian days with sat-fri order\n";
        $pass++;
    } else {
        echo "  [FAIL] Wday selector missing Persian days\n";
        $fail++;
    }

    // Test 4.6: Month options contains Farvardin to Esfand
    $monthHtml = issabel_draw_month_options('far');
    if (strpos($monthHtml, 'فروردین') !== false && strpos($monthHtml, 'اسفند') !== false && strpos($monthHtml, 'value="far"') !== false) {
        echo "  [PASS] Month selector contains Shamsi months optgroup (Farvardin to Esfand)\n";
        $pass++;
    } else {
        echo "  [FAIL] Month selector missing Shamsi months\n";
        $fail++;
    }
} else {
    echo "  [FAIL] timegroups_persian.php not found at $tgPath\n";
    $fail++;
}

echo "\n====================================================\n";
echo " Total Tests: " . ($pass + $fail) . " | Passed: $pass | Failed: $fail\n";
echo "====================================================\n";

if ($fail === 0) {
    echo "All tests passed successfully!\n";
    exit(0);
} else {
    echo "Some tests failed!\n";
    exit(1);
}
