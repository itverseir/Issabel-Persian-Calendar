/**
 * Issabel PBX - Persian Calendar & Shamsi DatePicker Engine
 * Complete all-in-one frontend integration for Issabel PBX Web GUI
 * 
 * Developed by: Amir Safari - ITVERSE.IR
 * Copyright (c) 2024-2026 Amir Safari - ITVERSE.IR. All rights reserved.
 * مالکیت مادی و معنوی: امیر صفری - ITVERSE.IR
 */

(function(window, document) {
    'use strict';

    // 1. Core Persian Date Algorithms
    var Core = window.PersianDateCore || {
        monthNames: [
            'فروردین', 'اردیبهشت', 'خرداد',
            'تیر', 'مرداد', 'شهریور',
            'مهر', 'آبان', 'آذر',
            'دی', 'بهمن', 'اسفند'
        ],
        weekDays: [
            'شنبه', 'یکشنبه', 'دوشنبه',
            'سه‌شنبه', 'چهارشنبه', 'پنج‌شنبه', 'جمعه'
        ],
        shortWeekDays: ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'],
        persianDigits: ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'],
        latinDigits: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],

        toPersianDigits: function(str) {
            if (str === null || str === undefined) return '';
            str = String(str);
            for (var i = 0; i < 10; i++) {
                str = str.replace(new RegExp(this.latinDigits[i], 'g'), this.persianDigits[i]);
            }
            return str;
        },

        toLatinDigits: function(str) {
            if (str === null || str === undefined) return '';
            str = String(str);
            for (var i = 0; i < 10; i++) {
                str = str.replace(new RegExp(this.persianDigits[i], 'g'), this.latinDigits[i]);
                str = str.replace(new RegExp(String.fromCharCode(1632 + i), 'g'), this.latinDigits[i]);
            }
            return str;
        },

        gregorianToJalali: function(gy, gm, gd) {
            var g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
            var jy = (gy > 1600) ? 979 : 0;
            gy -= (gy > 1600) ? 1600 : 621;
            var gy2 = (gm > 2) ? (gy + 1) : gy;
            var days = (365 * gy) + Math.floor((gy2 + 3) / 4) - Math.floor((gy2 + 99) / 100) + Math.floor((gy2 + 399) / 400) - 80 + gd + g_d_m[gm - 1];
            jy += 33 * Math.floor(days / 12053);
            days %= 12053;
            jy += 4 * Math.floor(days / 1461);
            days %= 1461;
            if (days > 365) {
                jy += Math.floor((days - 1) / 365);
                days = (days - 1) % 365;
            }
            var jm = (days < 186) ? 1 + Math.floor(days / 31) : 7 + Math.floor((days - 186) / 30);
            var jd = 1 + ((days < 186) ? (days % 31) : ((days - 186) % 30));
            return [jy, jm, jd];
        },

        jalaliToGregorian: function(jy, jm, jd) {
            var gy = (jy > 979) ? 1600 : 621;
            jy -= (jy > 979) ? 979 : 0;
            var days = (365 * jy) + (Math.floor(jy / 33) * 8) + Math.floor(((jy % 33) + 3) / 4) + 78 + jd + ((jm < 7) ? (jm - 1) * 31 : ((jm - 7) * 30) + 186);
            gy += 400 * Math.floor(days / 146097);
            days %= 146097;
            if (days > 36524) {
                gy += 100 * Math.floor(--days / 36524);
                days %= 36524;
                if (days >= 365) days++;
            }
            gy += 4 * Math.floor(days / 1461);
            days %= 1461;
            if (days > 365) {
                gy += Math.floor((days - 1) / 365);
                days = (days - 1) % 365;
            }
            var leap = ((gy % 4 === 0 && gy % 100 !== 0) || (gy % 400 === 0)) ? 29 : 28;
            var sal_a = [0, 31, leap, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
            var gm = 0;
            for (gm = 0; gm < 13 && days >= sal_a[gm]; gm++) {
                days -= sal_a[gm];
            }
            var gd = days + 1;
            return [gy, gm, gd];
        },

        isLeap: function(jy) {
            var g = this.jalaliToGregorian(jy, 12, 30);
            var j = this.gregorianToJalali(g[0], g[1], g[2]);
            return (j[0] === jy && j[1] === 12 && j[2] === 30);
        },

        monthDays: function(jy, jm) {
            if (jm >= 1 && jm <= 6) return 31;
            if (jm >= 7 && jm <= 11) return 30;
            if (jm === 12) return this.isLeap(jy) ? 30 : 29;
            return 30;
        },

        dayOfWeek: function(jy, jm, jd) {
            var g = this.jalaliToGregorian(jy, jm, jd);
            var d = new Date(g[0], g[1] - 1, g[2]);
            return (d.getDay() + 1) % 7; // 0: Sat, ..., 6: Fri
        },

        today: function() {
            var now = new Date();
            var j = this.gregorianToJalali(now.getFullYear(), now.getMonth() + 1, now.getDate());
            return {
                year: j[0],
                month: j[1],
                day: j[2],
                hour: now.getHours(),
                minute: now.getMinutes(),
                second: now.getSeconds(),
                dayOfWeek: this.dayOfWeek(j[0], j[1], j[2])
            };
        }
    };

    window.PersianDateCore = Core;

    var monthNamesEn = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
        'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
        'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
        'july': 7, 'august': 8, 'september': 9, 'october': 10, 'november': 11, 'december': 12
    };
    var monthNamesEnShort = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    // Default configuration
    var config = {
        enabled: true,
        datepicker_enabled: true,
        table_dates_enabled: true,
        header_clock_enabled: true,
        date_format: 'YYYY/MM/DD',
        digits: 'fa', // 'fa' or 'en'
        show_gregorian_tooltip: true,
        convert_backend_requests: true,
        show_day_of_week: true
    };

    if (window.ISSABEL_PERSIAN_CONFIG) {
        for (var k in window.ISSABEL_PERSIAN_CONFIG) {
            config[k] = window.ISSABEL_PERSIAN_CONFIG[k];
        }
    }

    if (!config.enabled) {
        return;
    }

    function pad2(n) {
        n = parseInt(n, 10);
        return (n < 10 ? '0' : '') + n;
    }

    // Convert Jalali year, month, day to Issabel's standard "d M Y" format (e.g. "15 Oct 2026")
    function toGregorianIssabelFormat(jy, jm, jd) {
        var g = Core.jalaliToGregorian(jy, jm, jd);
        var dStr = (g[2] < 10 ? '0' : '') + g[2];
        var mStr = monthNamesEnShort[g[1]];
        return dStr + ' ' + mStr + ' ' + g[0];
    }

    // Parse any Gregorian date string found in inputs or tables
    function parseAnyGregorianDate(val) {
        if (!val || typeof val !== 'string') return null;
        val = Core.toLatinDigits(val.trim());

        // 1. Textual: 15 Oct 2026 or 15-Oct-2026 or 15 Oct, 2026
        var mText = val.match(/^(\d{1,2})[\s-]+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s,-]+(20\d{2})/i);
        if (mText) {
            var d = parseInt(mText[1], 10);
            var m = monthNamesEn[mText[2].toLowerCase()];
            var y = parseInt(mText[3], 10);
            return { year: y, month: m, day: d };
        }

        // 2. ISO: YYYY-MM-DD or YYYY/MM/DD
        var mIso = val.match(/^(20\d{2})[-/](0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])/);
        if (mIso) {
            var y = parseInt(mIso[1], 10);
            var m = parseInt(mIso[2], 10);
            var d = parseInt(mIso[3], 10);
            return { year: y, month: m, day: d };
        }

        // 3. DD/MM/YYYY or DD-MM-YYYY (Call Recordings format): 15/10/2026
        var mDmy = val.match(/^([012]?\d|3[01])[-/](0?[1-9]|1[0-2])[-/](20\d{2})/);
        if (mDmy) {
            var d = parseInt(mDmy[1], 10);
            var m = parseInt(mDmy[2], 10);
            var y = parseInt(mDmy[3], 10);
            return { year: y, month: m, day: d };
        }

        return null;
    }

    // 2. Persian DatePicker UI Implementation
    var DatePicker = {
        popupEl: null,
        activeInput: null,
        viewYear: 0,
        viewMonth: 0,
        selectedYear: 0,
        selectedMonth: 0,
        selectedDay: 0,

        init: function() {
            if (this.popupEl) return;

            var el = document.createElement('div');
            el.className = 'issabel-datepicker-container';
            el.id = 'issabelDatePickerPopup';
            el.innerHTML =
                '<div class="issabel-datepicker-header">' +
                    '<button type="button" class="issabel-dp-nav-btn" id="issabelDpPrevMonth" title="ماه قبل">&rsaquo;</button>' +
                    '<div class="issabel-dp-title">' +
                        '<select class="issabel-dp-select" id="issabelDpMonthSelect"></select>' +
                        '<select class="issabel-dp-select" id="issabelDpYearSelect"></select>' +
                    '</div>' +
                    '<button type="button" class="issabel-dp-nav-btn" id="issabelDpNextMonth" title="ماه بعد">&lsaquo;</button>' +
                '</div>' +
                '<div class="issabel-datepicker-weekdays">' +
                    '<div class="issabel-dp-weekday">ش</div>' +
                    '<div class="issabel-dp-weekday">ی</div>' +
                    '<div class="issabel-dp-weekday">د</div>' +
                    '<div class="issabel-dp-weekday">س</div>' +
                    '<div class="issabel-dp-weekday">چ</div>' +
                    '<div class="issabel-dp-weekday">پ</div>' +
                    '<div class="issabel-dp-weekday is-friday">ج</div>' +
                '</div>' +
                '<div class="issabel-datepicker-days" id="issabelDpDaysGrid"></div>' +
                '<div class="issabel-datepicker-footer">' +
                    '<button type="button" class="issabel-dp-btn issabel-dp-btn-today" id="issabelDpBtnToday">امروز</button>' +
                    '<button type="button" class="issabel-dp-btn issabel-dp-btn-clear" id="issabelDpBtnClear">پاک کردن</button>' +
                    '<button type="button" class="issabel-dp-btn issabel-dp-btn-close" id="issabelDpBtnClose">بستن</button>' +
                '</div>';

            document.body.appendChild(el);
            this.popupEl = el;

            // Bind Events
            var self = this;
            document.getElementById('issabelDpPrevMonth').onclick = function(e) { e.stopPropagation(); self.prevMonth(); };
            document.getElementById('issabelDpNextMonth').onclick = function(e) { e.stopPropagation(); self.nextMonth(); };
            document.getElementById('issabelDpBtnToday').onclick = function(e) { e.stopPropagation(); self.selectToday(); };
            document.getElementById('issabelDpBtnClear').onclick = function(e) { e.stopPropagation(); self.clearInput(); };
            document.getElementById('issabelDpBtnClose').onclick = function(e) { e.stopPropagation(); self.hide(); };

            document.getElementById('issabelDpMonthSelect').onchange = function(e) {
                self.viewMonth = parseInt(this.value, 10);
                self.renderDays();
            };

            document.getElementById('issabelDpYearSelect').onchange = function(e) {
                self.viewYear = parseInt(this.value, 10);
                self.renderDays();
            };

            this.popupEl.onclick = function(e) {
                e.stopPropagation();
            };

            document.addEventListener('click', function(e) {
                if (self.activeInput && e.target !== self.activeInput && !self.popupEl.contains(e.target)) {
                    self.hide();
                }
            });

            window.addEventListener('resize', function() {
                if (self.activeInput) self.positionPopup();
            });
        },

        attach: function(input) {
            if (!input || input._issabelPersianAttached) return;
            input._issabelPersianAttached = true;

            // Remove native jQuery UI datepicker bindings if present
            if (window.jQuery) {
                try {
                    window.jQuery(input).off('.datepicker');
                } catch(e) {}
            }

            input.classList.add('issabel-persian-input');

            // Hook adjacent trigger button if present
            var next = input.nextElementSibling;
            if (next && (next.classList.contains('ui-datepicker-trigger') || next.className.indexOf('datepicker') !== -1)) {
                var self = this;
                next.addEventListener('click', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    self.show(input);
                });
            }

            // Format initial Gregorian value (e.g. "15 Oct 2026" or "2026-10-15") into Shamsi
            this.formatInitialValue(input);

            var self = this;
            input.addEventListener('focus', function() {
                self.show(input);
            });

            input.addEventListener('click', function(e) {
                e.stopPropagation();
                self.show(input);
            });
        },

        formatInitialValue: function(input) {
            var val = Core.toLatinDigits(input.value.trim());
            if (!val) return;

            var gDate = parseAnyGregorianDate(val);
            if (gDate) {
                var j = Core.gregorianToJalali(gDate.year, gDate.month, gDate.day);
                var sep = config.date_format.indexOf('/') !== -1 ? '/' : '-';
                var formatted = j[0] + sep + pad2(j[1]) + sep + pad2(j[2]);
                if (config.digits === 'fa') {
                    formatted = Core.toPersianDigits(formatted);
                }
                input.value = formatted;
                input.setAttribute('data-gregorian', toGregorianIssabelFormat(j[0], j[1], j[2]));
                input.setAttribute('data-gregorian-iso', gDate.year + '-' + pad2(gDate.month) + '-' + pad2(gDate.day));
            }
        },

        show: function(input) {
            this.init();
            this.activeInput = input;

            var today = Core.today();
            var initYear = today.year;
            var initMonth = today.month;
            var initDay = today.day;

            var val = Core.toLatinDigits(input.value.trim());

            // 1. Check if already has Jalali date
            var jMatch = val.match(/^(1[34]\d{2})[-/](0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])$/);
            if (jMatch) {
                initYear = parseInt(jMatch[1], 10);
                initMonth = parseInt(jMatch[2], 10);
                initDay = parseInt(jMatch[3], 10);
            } else {
                // 2. Check if it has a Gregorian date
                var gDate = parseAnyGregorianDate(val);
                if (gDate) {
                    var j = Core.gregorianToJalali(gDate.year, gDate.month, gDate.day);
                    initYear = j[0];
                    initMonth = j[1];
                    initDay = j[2];
                }
            }

            this.selectedYear = initYear;
            this.selectedMonth = initMonth;
            this.selectedDay = initDay;
            this.viewYear = initYear;
            this.viewMonth = initMonth;

            this.populateSelects();
            this.renderDays();
            this.positionPopup();

            this.popupEl.style.display = 'block';
        },

        hide: function() {
            if (this.popupEl) {
                this.popupEl.style.display = 'none';
            }
            this.activeInput = null;
        },

        positionPopup: function() {
            if (!this.activeInput || !this.popupEl) return;

            var rect = this.activeInput.getBoundingClientRect();
            var scrollLeft = window.pageXOffset || document.documentElement.scrollLeft;
            var scrollTop = window.pageYOffset || document.documentElement.scrollTop;

            var top = rect.bottom + scrollTop + 4;
            var left = rect.left + scrollLeft;

            var popupWidth = 290;
            if (left + popupWidth > window.innerWidth) {
                left = window.innerWidth - popupWidth - 10;
            }
            if (left < 10) left = 10;

            this.popupEl.style.top = top + 'px';
            this.popupEl.style.left = left + 'px';
        },

        populateSelects: function() {
            var mSelect = document.getElementById('issabelDpMonthSelect');
            mSelect.innerHTML = '';
            for (var m = 1; m <= 12; m++) {
                var opt = document.createElement('option');
                opt.value = m;
                opt.text = Core.monthNames[m - 1];
                if (m === this.viewMonth) opt.selected = true;
                mSelect.appendChild(opt);
            }

            var ySelect = document.getElementById('issabelDpYearSelect');
            ySelect.innerHTML = '';
            var today = Core.today();
            var startYear = today.year - 15;
            var endYear = today.year + 10;
            for (var y = startYear; y <= endYear; y++) {
                var yOpt = document.createElement('option');
                yOpt.value = y;
                yOpt.text = (config.digits === 'fa') ? Core.toPersianDigits(y) : y;
                if (y === this.viewYear) yOpt.selected = true;
                ySelect.appendChild(yOpt);
            }
        },

        renderDays: function() {
            var mSelect = document.getElementById('issabelDpMonthSelect');
            if (mSelect) mSelect.value = this.viewMonth;

            var ySelect = document.getElementById('issabelDpYearSelect');
            if (ySelect) ySelect.value = this.viewYear;

            var grid = document.getElementById('issabelDpDaysGrid');
            grid.innerHTML = '';

            var totalDays = Core.monthDays(this.viewYear, this.viewMonth);
            var firstDayOfWeek = Core.dayOfWeek(this.viewYear, this.viewMonth, 1);

            // Previous month trailing days
            var prevMonth = (this.viewMonth === 1) ? 12 : this.viewMonth - 1;
            var prevYear = (this.viewMonth === 1) ? this.viewYear - 1 : this.viewYear;
            var prevTotalDays = Core.monthDays(prevYear, prevMonth);

            for (var p = firstDayOfWeek - 1; p >= 0; p--) {
                var pDay = prevTotalDays - p;
                var pDiv = document.createElement('div');
                pDiv.className = 'issabel-dp-day is-other-month';
                pDiv.innerText = (config.digits === 'fa') ? Core.toPersianDigits(pDay) : pDay;
                grid.appendChild(pDiv);
            }

            // Current month days
            var today = Core.today();
            var self = this;

            for (var d = 1; d <= totalDays; d++) {
                var dayDiv = document.createElement('div');
                dayDiv.className = 'issabel-dp-day';

                var dow = (firstDayOfWeek + d - 1) % 7;
                if (dow === 6) {
                    dayDiv.classList.add('is-friday');
                }

                if (this.viewYear === today.year && this.viewMonth === today.month && d === today.day) {
                    dayDiv.classList.add('is-today');
                }

                if (this.viewYear === this.selectedYear && this.viewMonth === this.selectedMonth && d === this.selectedDay) {
                    dayDiv.classList.add('is-selected');
                }

                dayDiv.innerText = (config.digits === 'fa') ? Core.toPersianDigits(d) : d;
                dayDiv.setAttribute('data-day', d);

                dayDiv.onclick = (function(dayNum) {
                    return function(e) {
                        e.stopPropagation();
                        self.selectDate(self.viewYear, self.viewMonth, dayNum);
                    };
                })(d);

                grid.appendChild(dayDiv);
            }

            // Next month fill
            var usedSlots = firstDayOfWeek + totalDays;
            var remainder = (7 - (usedSlots % 7)) % 7;
            for (var n = 1; n <= remainder; n++) {
                var nDiv = document.createElement('div');
                nDiv.className = 'issabel-dp-day is-other-month';
                nDiv.innerText = (config.digits === 'fa') ? Core.toPersianDigits(n) : n;
                grid.appendChild(nDiv);
            }
        },

        prevMonth: function() {
            if (this.viewMonth === 1) {
                this.viewMonth = 12;
                this.viewYear--;
            } else {
                this.viewMonth--;
            }
            this.renderDays();
        },

        nextMonth: function() {
            if (this.viewMonth === 12) {
                this.viewMonth = 1;
                this.viewYear++;
            } else {
                this.viewMonth++;
            }
            this.renderDays();
        },

        selectDate: function(year, month, day) {
            if (!this.activeInput) return;

            var sep = config.date_format.indexOf('/') !== -1 ? '/' : '-';
            var formatted = year + sep + pad2(month) + sep + pad2(day);
            if (config.digits === 'fa') {
                formatted = Core.toPersianDigits(formatted);
            }

            var gIssabel = toGregorianIssabelFormat(year, month, day); // "15 Oct 2026"
            var g = Core.jalaliToGregorian(year, month, day);
            var gIso = g[0] + '-' + pad2(g[1]) + '-' + pad2(g[2]);

            this.activeInput.value = formatted;
            this.activeInput.setAttribute('data-gregorian', gIssabel);
            this.activeInput.setAttribute('data-gregorian-iso', gIso);

            var evt = document.createEvent('HTMLEvents');
            evt.initEvent('change', true, false);
            this.activeInput.dispatchEvent(evt);

            this.hide();
        },

        selectToday: function() {
            var t = Core.today();
            this.selectDate(t.year, t.month, t.day);
        },

        clearInput: function() {
            if (this.activeInput) {
                this.activeInput.value = '';
                this.activeInput.removeAttribute('data-gregorian');
                this.activeInput.removeAttribute('data-gregorian-iso');
                var evt = document.createEvent('HTMLEvents');
                evt.initEvent('change', true, false);
                this.activeInput.dispatchEvent(evt);
            }
            this.hide();
        }
    };

    // 3. Scan & Attach DatePickers to Form Inputs
    function scanAndAttachInputs(root) {
        if (!config.datepicker_enabled) return;
        root = root || document;

        var selectors = [
            'input.datepicker',
            'input.hasDatepicker',
            'input[id*="date"]',
            'input[name*="date"]',
            'input[id*="calldate"]',
            'input[name*="calldate"]',
            'input.issabel-persian-dp'
        ];

        var inputs = root.querySelectorAll(selectors.join(','));
        for (var i = 0; i < inputs.length; i++) {
            DatePicker.attach(inputs[i]);
        }
    }

    // 4. Hook jQuery UI Datepicker if present
    function hookJQueryDatePicker() {
        if (window.jQuery && window.jQuery.fn) {
            window.jQuery.fn.datepicker = function(options) {
                if (typeof options === 'string') {
                    if (options === 'getDate') {
                        var el = this[0];
                        if (el && el.getAttribute('data-gregorian-iso')) {
                            return new Date(el.getAttribute('data-gregorian-iso'));
                        }
                    } else if (options === 'destroy') {
                        return this;
                    }
                }

                return this.each(function() {
                    DatePicker.attach(this);
                });
            };

            if (!window.jQuery.datepicker) {
                window.jQuery.datepicker = {
                    setDefaults: function() {},
                    formatDate: function() { return ''; }
                };
            }
        }
    }

    // 5. Replace Date Patterns in Text String
    function replaceDatePatterns(text) {
        if (!text || typeof text !== 'string') return text;
        var sep = config.date_format.indexOf('/') !== -1 ? '/' : '-';

        // Pattern 1: Textual Month (e.g. 15 Oct 2026 or 15-Oct-2026 or 15 Oct, 2026)
        text = text.replace(/\b(0?[1-9]|[12]\d|3[01])[\s-]+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s,-]+(20\d{2})\b/gi, function(match, d, mStr, y) {
            var gm = monthNamesEn[mStr.toLowerCase()];
            if (!gm) return match;
            var gd = parseInt(d, 10);
            var gy = parseInt(y, 10);
            var j = Core.gregorianToJalali(gy, gm, gd);
            var formatted = j[0] + sep + pad2(j[1]) + sep + pad2(j[2]);
            if (config.digits === 'fa') formatted = Core.toPersianDigits(formatted);
            var title = config.show_gregorian_tooltip ? ' title="میلادی: ' + match + '"' : '';
            return '<span class="issabel-shamsi-date"' + title + '>' + formatted + '</span>';
        });

        // Pattern 2: DD/MM/YYYY or DD-MM-YYYY (Call Recordings / monitoring format): 15/10/2026
        text = text.replace(/\b(0?[1-9]|[12]\d|3[01])[\/-](0?[1-9]|1[0-2])[\/-](20\d{2})(?:\s+([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?)?\b/g, function(match, d, m, y, hh, mm, ss) {
            var gd = parseInt(d, 10);
            var gm = parseInt(m, 10);
            var gy = parseInt(y, 10);
            var j = Core.gregorianToJalali(gy, gm, gd);
            var formatted = j[0] + sep + pad2(j[1]) + sep + pad2(j[2]);
            if (hh !== undefined && mm !== undefined) {
                formatted += ' ' + pad2(hh) + ':' + pad2(mm);
                if (ss !== undefined) formatted += ':' + pad2(ss);
            }
            if (config.digits === 'fa') formatted = Core.toPersianDigits(formatted);
            var title = config.show_gregorian_tooltip ? ' title="میلادی: ' + match + '"' : '';
            return '<span class="issabel-shamsi-date"' + title + '>' + formatted + '</span>';
        });

        // Pattern 3: YYYY-MM-DD or YYYY/MM/DD with optional time: 2026-10-15 00:00:00
        text = text.replace(/\b(20\d{2})[\/-](0?[1-9]|1[0-2])[\/-](0?[1-9]|[12]\d|3[01])(?:\s+([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?)?\b/g, function(match, y, m, d, hh, mm, ss) {
            var gy = parseInt(y, 10);
            var gm = parseInt(m, 10);
            var gd = parseInt(d, 10);
            var j = Core.gregorianToJalali(gy, gm, gd);
            var formatted = j[0] + sep + pad2(j[1]) + sep + pad2(j[2]);
            if (hh !== undefined && mm !== undefined) {
                formatted += ' ' + pad2(hh) + ':' + pad2(mm);
                if (ss !== undefined) formatted += ':' + pad2(ss);
            }
            if (config.digits === 'fa') formatted = Core.toPersianDigits(formatted);
            var title = config.show_gregorian_tooltip ? ' title="میلادی: ' + match + '"' : '';
            return '<span class="issabel-shamsi-date"' + title + '>' + formatted + '</span>';
        });

        return text;
    }

    // Safely replace dates ONLY in DOM text nodes, never modifying HTML attributes or links
    function replaceDatesInElement(element) {
        if (!element) return;
        var children = element.childNodes;
        for (var i = 0; i < children.length; i++) {
            var node = children[i];
            if (node.nodeType === 3) { // Text node
                var text = node.nodeValue;
                if (text && text.length >= 8 && text.indexOf('20') !== -1) {
                    var replaced = replaceDatePatterns(text);
                    if (replaced !== text) {
                        var temp = document.createElement('span');
                        temp.className = 'issabel-date-wrapper';
                        temp.innerHTML = replaced;
                        element.replaceChild(temp, node);
                    }
                }
            } else if (node.nodeType === 1) { // Element node
                var tag = node.tagName.toUpperCase();
                if (tag === 'SCRIPT' || tag === 'STYLE' || tag === 'TEXTAREA' || tag === 'INPUT' || tag === 'SELECT' || tag === 'BUTTON') {
                    continue;
                }
                if (node.classList && (node.classList.contains('issabel-shamsi-date') || node.classList.contains('issabel-date-wrapper'))) {
                    continue;
                }
                replaceDatesInElement(node);
            }
        }
    }

    // 6. Dynamic Table, Grid & Filter Date Converter (CDR, Monitoring, Logs, Queues, Summary)
    function convertAllDatesInDoc(root) {
        if (!config.table_dates_enabled) return;
        root = root || document;

        var selectors = [
            'table td', 'table th',
            '#msgFilter', '.neo-filter-control',
            '.neo-table-filter-applied', '.neo-table-filter-row',
            '.neo-table-header-filterrow',
            'div[class*="filter"]', 'div[class*="Filter"]',
            'span[class*="filter"]', 'span[class*="Filter"]',
            '.alert', 'span.filter'
        ];

        var elements = root.querySelectorAll(selectors.join(','));
        for (var i = 0; i < elements.length; i++) {
            replaceDatesInElement(elements[i]);
        }
    }

    // 7. Watch for iframes (such as CDR Details CEL popup)
    function watchIframes() {
        var iframes = document.querySelectorAll('iframe');
        for (var i = 0; i < iframes.length; i++) {
            var frame = iframes[i];
            if (frame._issabelPersianWatched) continue;
            frame._issabelPersianWatched = true;

            frame.addEventListener('load', function() {
                try {
                    var doc = this.contentDocument || this.contentWindow.document;
                    if (doc && doc.body) {
                        convertAllDatesInDoc(doc.body);
                        if (window.MutationObserver) {
                            var obs = new MutationObserver(function() {
                                convertAllDatesInDoc(doc.body);
                            });
                            obs.observe(doc.body, { childList: true, subtree: true });
                        }
                    }
                } catch(e) {}
            });
        }
    }

    // 8. Header Live Persian Clock Badge
    function initHeaderClock() {
        if (!config.header_clock_enabled) return;

        var clockBadge = document.getElementById('issabelPersianClockBadge');
        if (!clockBadge) {
            clockBadge = document.createElement('div');
            clockBadge.id = 'issabelPersianClockBadge';
            clockBadge.className = 'issabel-persian-clock-badge';

            var wrap = document.createElement('span');
            wrap.id = 'issabelClockWrap';
            var bodyClass = (document.body && document.body.className) ? String(document.body.className) : '';
            var isRtl = document.dir === 'rtl' || (document.body && document.body.dir === 'rtl') || bodyClass.indexOf('rtl') !== -1;
            wrap.style.cssText = isRtl
                ? 'float:right; padding:18px 15px 0 0; display:inline-block; vertical-align:middle; z-index:999;'
                : 'float:left; padding:18px 0 0 15px; display:inline-block; vertical-align:middle; z-index:999;';
            wrap.appendChild(clockBadge);

            var topbar = document.querySelector('.main-content > div[style*="373e4a"], .main-content > div:first-child, .user-info, .navbar-custom-menu');
            if (topbar) {
                if (topbar.tagName === 'UL') {
                    var li = document.createElement('li');
                    li.className = 'profile-info';
                    li.appendChild(clockBadge);
                    topbar.insertBefore(li, topbar.firstChild);
                } else {
                    topbar.insertBefore(wrap, topbar.firstChild);
                }
            } else {
                document.body.insertBefore(wrap, document.body.firstChild);
            }
        }

        function updateClock() {
            var now = Core.today();
            var dayName = Core.weekDays[now.dayOfWeek];
            var monthName = Core.monthNames[now.month - 1];

            var dStr = (config.digits === 'fa') ? Core.toPersianDigits(now.day) : now.day;
            var yStr = (config.digits === 'fa') ? Core.toPersianDigits(now.year) : now.year;
            var hStr = pad2(now.hour);
            var mStr = pad2(now.minute);
            var sStr = pad2(now.second);

            if (config.digits === 'fa') {
                hStr = Core.toPersianDigits(hStr);
                mStr = Core.toPersianDigits(mStr);
                sStr = Core.toPersianDigits(sStr);
            }

            clockBadge.innerHTML =
                '<span class="clock-icon">📅</span> ' +
                '<span>' + dayName + '، ' + dStr + ' ' + monthName + ' ' + yStr + '</span>' +
                '<span style="opacity:0.5">|</span>' +
                '<span class="clock-icon">⏰</span> ' +
                '<span class="clock-time">' + hStr + ':' + mStr + ':' + sStr + '</span>';
        }

        updateClock();
        if (!window._issabelPersianClockTimer) {
            window._issabelPersianClockTimer = setInterval(updateClock, 1000);
        }
    }

    // 9. Form Submission Interceptor: sends Issabel's native "d M Y" format (e.g. "15 Oct 2026")
    function hookFormSubmissions() {
        document.addEventListener('submit', function(e) {
            var form = e.target;
            var inputs = form.querySelectorAll('input.issabel-persian-input, input[id*="date"], input[name*="date"]');
            for (var i = 0; i < inputs.length; i++) {
                var input = inputs[i];
                var val = Core.toLatinDigits(input.value.trim());
                var jMatch = val.match(/^(1[34]\d{2})[-/](0?[1-9]|1[0-2])[-/](0?[1-9]|[12]\d|3[01])$/);
                if (jMatch) {
                    var jy = parseInt(jMatch[1], 10);
                    var jm = parseInt(jMatch[2], 10);
                    var jd = parseInt(jMatch[3], 10);
                    // Set to "d M Y" format expected by all Issabel form validators and translateDate
                    input.value = toGregorianIssabelFormat(jy, jm, jd);
                }
            }
        }, true);
    }

    // 10. Bootstrap everything
    function bootstrap() {
        hookJQueryDatePicker();
        scanAndAttachInputs(document);
        convertAllDatesInDoc(document);
        initHeaderClock();
        setTimeout(initHeaderClock, 500);
        setTimeout(initHeaderClock, 1500);
        hookFormSubmissions();
        watchIframes();

        if (window.MutationObserver) {
            var debounceTimer = null;
            var observer = new MutationObserver(function(mutations) {
                var shouldProcess = false;
                for (var i = 0; i < mutations.length; i++) {
                    var m = mutations[i];
                    if (m.target && m.target.id === 'issabelDatePickerPopup') continue;
                    if (m.target && m.target.id === 'issabelPersianClockBadge') continue;
                    if (m.target && (m.target.className === 'issabel-date-wrapper' || m.target.className === 'issabel-shamsi-date')) continue;
                    shouldProcess = true;
                    break;
                }
                if (!shouldProcess) return;

                clearTimeout(debounceTimer);
                debounceTimer = setTimeout(function() {
                    scanAndAttachInputs(document);
                    convertAllDatesInDoc(document);
                    watchIframes();
                }, 200);
            });
            observer.observe(document.body, { childList: true, subtree: true });
        }

        if (window.jQuery) {
            window.jQuery(document).ajaxComplete(function() {
                scanAndAttachInputs(document);
                convertAllDatesInDoc(document);
                watchIframes();
            });
            window.jQuery(document).on('draw.dt init.dt responsive-display.dt', function(e) {
                convertAllDatesInDoc(document);
            });
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', bootstrap);
    } else {
        bootstrap();
    }

})(window, document);
