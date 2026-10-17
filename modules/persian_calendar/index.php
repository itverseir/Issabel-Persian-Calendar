<?php
/*
  Issabel PBX - Persian Calendar Module Controller
  Developed by: Amir Safari - ITVERSE.IR
  Copyright (c) 2024-2026 Amir Safari - ITVERSE.IR. All rights reserved.
  مالکیت مادی و معنوی: امیر صفری - ITVERSE.IR
*/

function _moduleContent(&$smarty, $module_name) {
    // Include module files
    include_once "modules/$module_name/configs/default.conf.php";
    include_once "modules/$module_name/libs/jdf.php";
    include_once "modules/$module_name/libs/paloSantoPersianCalendar.class.php";

    // Load language dictionary
    load_language_module($module_name);

    $pPersian = new paloSantoPersianCalendar();
    $messageSuccess = '';
    $messageError = '';

    // Handle form submissions
    $action = isset($_POST['action']) ? $_POST['action'] : '';

    if ($action === 'save_settings') {
        $newConfig = array(
            'enabled'                   => isset($_POST['enabled']) ? true : false,
            'datepicker_enabled'        => isset($_POST['datepicker_enabled']) ? true : false,
            'table_dates_enabled'       => isset($_POST['table_dates_enabled']) ? true : false,
            'header_clock_enabled'      => isset($_POST['header_clock_enabled']) ? true : false,
            'convert_backend_requests'  => isset($_POST['convert_backend_requests']) ? true : false,
            'digits'                    => (isset($_POST['digits']) && $_POST['digits'] === 'en') ? 'en' : 'fa',
            'date_format'               => (isset($_POST['date_format']) && $_POST['date_format'] === 'YYYY-MM-DD') ? 'YYYY-MM-DD' : 'YYYY/MM/DD'
        );

        if ($pPersian->saveConfig($newConfig)) {
            $messageSuccess = _tr("Settings saved successfully");
        } else {
            $messageError = _tr("Could not save settings");
        }
    } elseif ($action === 'repair_hooks') {
        $results = $pPersian->applyHooks();
        $messageSuccess = _tr("Hooks applied successfully");
    }

    $config = $pPersian->getConfig();
    $status = $pPersian->getSystemStatus();

    // Assign template variables
    $smarty->assign("MODULE_TITLE", _tr("Persian Calendar Module"));
    $smarty->assign("CONFIG", $config);
    $smarty->assign("STATUS", $status);
    $smarty->assign("MESSAGE_SUCCESS", $messageSuccess);
    $smarty->assign("MESSAGE_ERROR", $messageError);

    $smarty->assign("CURRENT_GREGORIAN", date('Y-m-d'));
    $smarty->assign("CURRENT_JALALI", issabel_jdate('Y/m/d'));

    // Path to template
    $baseDir = dirname(__FILE__);
    return $smarty->fetch("file:$baseDir/themes/default/index.tpl");
}
