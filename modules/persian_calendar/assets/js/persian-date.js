/**
 * Persian (Jalali) Calendar Math Engine
 * High-precision astronomical and algorithmic conversion for Issabel PBX
 */

(function(root) {
    'use strict';

    var PersianDateCore = {
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
                // Arabic-indic digits support as well
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
            // Gregorian 0 (Sun) to 6 (Sat).
            // Persian week starts Saturday (0), Sunday (1), ..., Friday (6)
            return (d.getDay() + 1) % 7;
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
        },

        formatDate: function(jy, jm, jd, format, usePersianDigits) {
            format = format || 'YYYY/MM/DD';
            var pad = function(n) { return (n < 10 ? '0' : '') + n; };
            var str = format
                .replace(/YYYY/g, String(jy))
                .replace(/YY/g, String(jy).slice(-2))
                .replace(/MMMM/g, this.monthNames[jm - 1])
                .replace(/MM/g, pad(jm))
                .replace(/M/g, String(jm))
                .replace(/DD/g, pad(jd))
                .replace(/D/g, String(jd));

            if (usePersianDigits) {
                return this.toPersianDigits(str);
            }
            return str;
        }
    };

    root.PersianDateCore = PersianDateCore;
})(typeof window !== 'undefined' ? window : global);
