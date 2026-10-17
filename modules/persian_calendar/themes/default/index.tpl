{*
  Issabel PBX - Persian Calendar Module Admin Template
*}

<style>
.pc-container {
    padding: 15px;
    font-family: 'Vazirmatn', 'Tahoma', 'Segoe UI', Arial, sans-serif;
    color: #2c3e50;
}
.pc-card {
    background: #ffffff;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.04);
    margin-bottom: 20px;
    overflow: hidden;
}
.pc-card-header {
    background: #2b3d51;
    color: #ffffff;
    padding: 14px 20px;
    font-size: 16px;
    font-weight: 600;
    display: flex;
    justify-content: space-between;
    align-items: center;
}
.pc-card-body {
    padding: 20px;
}
.pc-nav-tabs {
    display: flex;
    gap: 5px;
    border-bottom: 2px solid #e2e8f0;
    margin-bottom: 20px;
    padding: 0;
    list-style: none;
}
.pc-nav-tab {
    padding: 10px 18px;
    cursor: pointer;
    font-weight: 600;
    font-size: 13px;
    border-bottom: 3px solid transparent;
    transition: all 0.2s;
    color: #64748b;
}
.pc-nav-tab.active {
    color: #1a73e8;
    border-bottom-color: #1a73e8;
}
.pc-tab-content {
    display: none;
}
.pc-tab-content.active {
    display: block;
}
.pc-form-group {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 12px 0;
    border-bottom: 1px solid #f1f5f9;
}
.pc-form-group:last-child {
    border-bottom: none;
}
.pc-form-label {
    font-weight: 600;
    font-size: 13px;
    color: #334155;
}
.pc-form-desc {
    font-size: 11px;
    color: #64748b;
    margin-top: 3px;
}
.pc-switch {
    position: relative;
    display: inline-block;
    width: 46px;
    height: 24px;
}
.pc-switch input {
    opacity: 0;
    width: 0;
    height: 0;
}
.pc-slider {
    position: absolute;
    cursor: pointer;
    top: 0; left: 0; right: 0; bottom: 0;
    background-color: #cbd5e1;
    transition: .3s;
    border-radius: 24px;
}
.pc-slider:before {
    position: absolute;
    content: "";
    height: 18px;
    width: 18px;
    left: 3px;
    bottom: 3px;
    background-color: white;
    transition: .3s;
    border-radius: 50%;
}
input:checked + .pc-slider {
    background-color: #1a73e8;
}
input:checked + .pc-slider:before {
    transform: translateX(22px);
}
.pc-select, .pc-input {
    padding: 7px 12px;
    border: 1px solid #cbd5e1;
    border-radius: 6px;
    font-size: 13px;
    font-family: inherit;
    outline: none;
    background: #fff;
    min-width: 180px;
}
.pc-select:focus, .pc-input:focus {
    border-color: #1a73e8;
}
.pc-btn {
    padding: 9px 20px;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-family: inherit;
    font-weight: 600;
    font-size: 13px;
    transition: background 0.2s;
    display: inline-flex;
    align-items: center;
    gap: 6px;
}
.pc-btn-primary {
    background: #1a73e8;
    color: #ffffff;
}
.pc-btn-primary:hover {
    background: #1557b0;
}
.pc-btn-success {
    background: #10b981;
    color: #ffffff;
}
.pc-btn-success:hover {
    background: #059669;
}
.pc-btn-secondary {
    background: #e2e8f0;
    color: #334155;
}
.pc-btn-secondary:hover {
    background: #cbd5e1;
}
.pc-alert {
    padding: 12px 16px;
    border-radius: 6px;
    margin-bottom: 20px;
    font-size: 13px;
    display: flex;
    align-items: center;
    gap: 8px;
}
.pc-alert-success {
    background: #ecfdf5;
    color: #065f46;
    border: 1px solid #a7f3d0;
}
.pc-alert-danger {
    background: #fef2f2;
    color: #991b1b;
    border: 1px solid #fecaca;
}
.pc-badge {
    padding: 4px 10px;
    border-radius: 12px;
    font-size: 11px;
    font-weight: 600;
}
.pc-badge-success {
    background: #d1fae5;
    color: #065f46;
}
.pc-badge-danger {
    background: #fee2e2;
    color: #991b1b;
}
.pc-table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 10px;
}
.pc-table th, .pc-table td {
    padding: 12px 14px;
    text-align: right;
    border-bottom: 1px solid #e2e8f0;
    font-size: 13px;
}
.pc-table th {
    background: #f8fafc;
    color: #475569;
}
.pc-converter-box {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    padding: 20px;
    margin-bottom: 15px;
}
</style>

<div class="pc-container">
    {if $MESSAGE_SUCCESS}
        <div class="pc-alert pc-alert-success">
            <span>✔</span> {$MESSAGE_SUCCESS}
        </div>
    {/if}
    {if $MESSAGE_ERROR}
        <div class="pc-alert pc-alert-danger">
            <span>✖</span> {$MESSAGE_ERROR}
        </div>
    {/if}

    <div class="pc-card">
        <div class="pc-card-header">
            <div>
                <span>📅 {$MODULE_TITLE}</span>
                <span style="font-size: 12px; opacity: 0.85; margin-right: 10px;">نسخه 1.0</span>
            </div>
            <div>
                {if $CONFIG.enabled}
                    <span class="pc-badge pc-badge-success">فعال</span>
                {else}
                    <span class="pc-badge pc-badge-danger">غیرفعال</span>
                {/if}
            </div>
        </div>

        <div class="pc-card-body">
            <ul class="pc-nav-tabs">
                <li class="pc-nav-tab active" onclick="pcSwitchTab(this, 'tabSettings')">⚙ تنظیمات عمومی</li>
                <li class="pc-nav-tab" onclick="pcSwitchTab(this, 'tabConverter')">🔄 ابزار تبدیل تاریخ</li>
                <li class="pc-nav-tab" onclick="pcSwitchTab(this, 'tabStatus')">🔍 وضعیت سیستم و عیب‌یابی</li>
            </ul>

            <!-- Tab 1: General Settings -->
            <div id="tabSettings" class="pc-tab-content active">
                <form method="POST" action="?menu=persian_calendar">
                    <input type="hidden" name="action" value="save_settings">

                    <div class="pc-form-group">
                        <div>
                            <div class="pc-form-label">فعال‌سازی تقویم شمسی</div>
                            <div class="pc-form-desc">فعال یا غیرفعال کردن سراسری ماژول تقویم شمسی در سیستم ایزابل</div>
                        </div>
                        <label class="pc-switch">
                            <input type="checkbox" name="enabled" value="1" {if $CONFIG.enabled}checked{/if}>
                            <span class="pc-slider"></span>
                        </label>
                    </div>

                    <div class="pc-form-group">
                        <div>
                            <div class="pc-form-label">دیت‌پیکر تقویم شمسی در فرم‌ها</div>
                            <div class="pc-form-desc">نمایش تقویم شمسی با امکان انتخاب سال، ماه و روز در فیلدهای گزارشات (CDR، ضبط مکالمات و ...)</div>
                        </div>
                        <label class="pc-switch">
                            <input type="checkbox" name="datepicker_enabled" value="1" {if $CONFIG.datepicker_enabled}checked{/if}>
                            <span class="pc-slider"></span>
                        </label>
                    </div>

                    <div class="pc-form-group">
                        <div>
                            <div class="pc-form-label">تبدیل خودکار تاریخ در جداول سیستم</div>
                            <div class="pc-form-desc">تبدیل زمان‌های ثبت مکالمات و رویدادها در جداول CDR و لاگ‌ها به تاریخ شمسی با قابلیت نمایش میلادی در Tooltip</div>
                        </div>
                        <label class="pc-switch">
                            <input type="checkbox" name="table_dates_enabled" value="1" {if $CONFIG.table_dates_enabled}checked{/if}>
                            <span class="pc-slider"></span>
                        </label>
                    </div>

                    <div class="pc-form-group">
                        <div>
                            <div class="pc-form-label">ساعت و تاریخ زنده شمسی در نوار سیستم</div>
                            <div class="pc-form-desc">نمایش تاریخ امروز و ساعت جاری به صورت زنده در هدر بالایی پنل ایزابل</div>
                        </div>
                        <label class="pc-switch">
                            <input type="checkbox" name="header_clock_enabled" value="1" {if $CONFIG.header_clock_enabled}checked{/if}>
                            <span class="pc-slider"></span>
                        </label>
                    </div>

                    <div class="pc-form-group">
                        <div>
                            <div class="pc-form-label">تبدیل شفاف تاریخ در کوئری‌ها (Backend Interceptor)</div>
                            <div class="pc-form-desc">تبدیل خودکار بازه‌های تاریخی شمسی ارسالی در فیلترها به میلادی برای جلوگیری از خطا در کوئری دیتابیس استریسک</div>
                        </div>
                        <label class="pc-switch">
                            <input type="checkbox" name="convert_backend_requests" value="1" {if $CONFIG.convert_backend_requests}checked{/if}>
                            <span class="pc-slider"></span>
                        </label>
                    </div>

                    <div class="pc-form-group">
                        <div>
                            <div class="pc-form-label">فرمت نمایش اعداد</div>
                            <div class="pc-form-desc">انتخاب نحوه نمایش ارقام در تاریخ‌ها</div>
                        </div>
                        <select name="digits" class="pc-select">
                            <option value="fa" {if $CONFIG.digits == 'fa'}selected{/if}>فارسی (۱۴۰۳/۰۸/۱۵)</option>
                            <option value="en" {if $CONFIG.digits == 'en'}selected{/if}>لاتین (1403/08/15)</option>
                        </select>
                    </div>

                    <div class="pc-form-group">
                        <div>
                            <div class="pc-form-label">فرمت تاریخ شمسی</div>
                            <div class="pc-form-desc">جداکننده تاریخ در دیت‌پیکرها و جدول‌ها</div>
                        </div>
                        <select name="date_format" class="pc-select">
                            <option value="YYYY/MM/DD" {if $CONFIG.date_format == 'YYYY/MM/DD'}selected{/if}>YYYY/MM/DD (اسلش)</option>
                            <option value="YYYY-MM-DD" {if $CONFIG.date_format == 'YYYY-MM-DD'}selected{/if}>YYYY-MM-DD (خط تیره)</option>
                        </select>
                    </div>

                    <div style="margin-top: 25px;">
                        <button type="submit" class="pc-btn pc-btn-primary">💾 ذخیره تغییرات</button>
                    </div>
                </form>
            </div>

            <!-- Tab 2: Live Converter -->
            <div id="tabConverter" class="pc-tab-content">
                <div class="pc-converter-box">
                    <h4 style="margin-top: 0; color: #1e293b;">🔄 تبدیل تاریخ میلادی به شمسی</h4>
                    <div style="display: flex; gap: 10px; align-items: center; margin-top: 10px;">
                        <input type="text" id="gregInput" class="pc-input" placeholder="مثال: 2024-11-05" value="{$CURRENT_GREGORIAN}">
                        <button type="button" class="pc-btn pc-btn-primary" onclick="pcConvertG2J()">تبدیل به شمسی</button>
                    </div>
                    <div id="g2jResult" style="margin-top: 12px; font-weight: bold; color: #15803d;"></div>
                </div>

                <div class="pc-converter-box">
                    <h4 style="margin-top: 0; color: #1e293b;">🔄 تبدیل تاریخ شمسی به میلادی</h4>
                    <div style="display: flex; gap: 10px; align-items: center; margin-top: 10px;">
                        <input type="text" id="jalaliInput" class="pc-input" placeholder="مثال: 1403/08/15" value="{$CURRENT_JALALI}">
                        <button type="button" class="pc-btn pc-btn-primary" onclick="pcConvertJ2G()">تبدیل به میلادی</button>
                    </div>
                    <div id="j2gResult" style="margin-top: 12px; font-weight: bold; color: #1d4ed8;"></div>
                </div>
            </div>

            <!-- Tab 3: System Status & Diagnostics -->
            <div id="tabStatus" class="pc-tab-content">
                <table class="pc-table">
                    <thead>
                        <tr>
                            <th>مؤلفه سیستم</th>
                            <th>توضیحات</th>
                            <th>وضعیت</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td><strong>هوک ورودی index.php</strong></td>
                            <td>تزریق هوک جهت خواندن خودکار تاریخ‌های شمسی در درخواست‌ها</td>
                            <td>
                                {if $STATUS.hook_index}
                                    <span class="pc-badge pc-badge-success">متصل و فعال</span>
                                {else}
                                    <span class="pc-badge pc-badge-danger">متصل نشده</span>
                                {/if}
                            </td>
                        </tr>
                        <tr>
                            <td><strong>قالب پیش‌فرض (Tenant)</strong></td>
                            <td>اتصال فایل‌های CSS و JS دیت‌پیکر در قالب فعال ایزابل</td>
                            <td>
                                {if $STATUS.theme_tenant}
                                    <span class="pc-badge pc-badge-success">متصل است</span>
                                {else}
                                    <span class="pc-badge pc-badge-danger">نیاز به تزریق</span>
                                {/if}
                            </td>
                        </tr>
                        <tr>
                            <td><strong>قالب فارسی راست‌چین (Farsi RTL)</strong></td>
                            <td>اتصال فایل‌های CSS و JS دیت‌پیکر در قالب farsi_rtl</td>
                            <td>
                                {if $STATUS.theme_farsi}
                                    <span class="pc-badge pc-badge-success">متصل است</span>
                                {else}
                                    <span class="pc-badge pc-badge-secondary" style="background:#f1f5f9;color:#64748b;">غیرفعال / نیاز به تزریق</span>
                                {/if}
                            </td>
                        </tr>
                        <tr>
                            <td><strong>قالب نئو (ElastixNeo)</strong></td>
                            <td>اتصال استایل‌ها و اسکریپت‌ها در قالب ElastixNeo</td>
                            <td>
                                {if $STATUS.theme_neo}
                                    <span class="pc-badge pc-badge-success">متصل است</span>
                                {else}
                                    <span class="pc-badge pc-badge-secondary" style="background:#f1f5f9;color:#64748b;">قالب غیرفعال</span>
                                {/if}
                            </td>
                        </tr>
                        <tr>
                            <td><strong>دسترسی فایل تنظیمات</strong></td>
                            <td>قابلیت ذخیره تنظیمات ماژول در سرور</td>
                            <td>
                                {if $STATUS.config_writable}
                                    <span class="pc-badge pc-badge-success">قابل نوشتن</span>
                                {else}
                                    <span class="pc-badge pc-badge-danger">دسترسی محدود</span>
                                {/if}
                            </td>
                        </tr>
                        <tr>
                            <td><strong>نسخه PHP سرور</strong></td>
                            <td>سازگاری توابع ریاضی و دیتابیس</td>
                            <td><span class="pc-badge pc-badge-success">PHP {$STATUS.php_version}</span></td>
                        </tr>
                    </tbody>
                </table>

                <div style="margin-top: 25px;">
                    <form method="POST" action="?menu=persian_calendar" style="display:inline-block;">
                        <input type="hidden" name="action" value="repair_hooks">
                        <button type="submit" class="pc-btn pc-btn-success">🔧 بازسازی و اتصال مجدد هوک‌ها</button>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Footer Copyright -->
    <div style="text-align: center; margin-top: 25px; padding: 15px; font-size: 13px; color: #64748b; border-top: 1px solid #e2e8f0;">
        ماژول تقویم و تاریخ شمسی ایزابل | توسعه‌دهنده و مالکیت معنوی: 
        <strong style="color: #1e293b;">امیر صفری</strong> 
        (<a href="https://itverse.ir" target="_blank" style="color: #1a73e8; text-decoration: none; font-weight: 600;">ITVERSE.IR</a>)
    </div>
</div>

{literal}
<script>
function pcSwitchTab(tabEl, contentId) {
    var tabs = document.querySelectorAll('.pc-nav-tab');
    for (var i = 0; i < tabs.length; i++) tabs[i].classList.remove('active');
    tabEl.classList.add('active');

    var contents = document.querySelectorAll('.pc-tab-content');
    for (var j = 0; j < contents.length; j++) contents[j].classList.remove('active');
    var target = document.getElementById(contentId);
    if (target) target.classList.add('active');
}

function pcConvertG2J() {
    var input = document.getElementById('gregInput').value.trim();
    var match = input.match(/^(\d{4})[-\/](\d{1,2})[-\/](\d{1,2})/);
    if (!match) {
        document.getElementById('g2jResult').innerText = 'فرمت تاریخ نامعتبر است (مثال صحیح: 2024-11-05)';
        return;
    }
    var gy = parseInt(match[1], 10);
    var gm = parseInt(match[2], 10);
    var gd = parseInt(match[3], 10);
    if (window.PersianDateCore) {
        var j = window.PersianDateCore.gregorianToJalali(gy, gm, gd);
        var dow = window.PersianDateCore.dayOfWeek(j[0], j[1], j[2]);
        var mName = window.PersianDateCore.monthNames[j[1] - 1];
        var dName = window.PersianDateCore.weekDays[dow];
        document.getElementById('g2jResult').innerHTML =
            'نتیجه: ' + j[0] + '/' + (j[1] < 10 ? '0' : '') + j[1] + '/' + (j[2] < 10 ? '0' : '') + j[2] +
            ' (' + dName + '، ' + j[2] + ' ' + mName + ' ' + j[0] + ')';
    }
}

function pcConvertJ2G() {
    var input = document.getElementById('jalaliInput').value.trim();
    if (window.PersianDateCore) {
        input = window.PersianDateCore.toLatinDigits(input);
    }
    var match = input.match(/^(\d{4})[-\/](\d{1,2})[-\/](\d{1,2})/);
    if (!match) {
        document.getElementById('j2gResult').innerText = 'فرمت تاریخ نامعتبر است (مثال صحیح: 1403/08/15)';
        return;
    }
    var jy = parseInt(match[1], 10);
    var jm = parseInt(match[2], 10);
    var jd = parseInt(match[3], 10);
    if (window.PersianDateCore) {
        var g = window.PersianDateCore.jalaliToGregorian(jy, jm, jd);
        document.getElementById('j2gResult').innerHTML =
            'نتیجه میلادی: ' + g[0] + '-' + (g[1] < 10 ? '0' : '') + g[1] + '-' + (g[2] < 10 ? '0' : '') + g[2];
    }
}
</script>
{/literal}
