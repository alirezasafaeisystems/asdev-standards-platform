# نقشه‌راه یکپارچه (Phase/Milestone/Task محور)

> این نقشه‌راه **زمان‌محور نیست** و بر مبنای فاز، مایلستون، تسک، نقش و دامنه پروژه تدوین شده است.

## دامنه پروژه‌ها
- `asdev-standards-platform`: هاب استانداردسازی و اتوماسیون.
- پروژه‌های سازمان GitHub: به دلیل نبود `gh` در محیط فعلی، inventory مستقیم کامل نشده و به‌عنوان گپ اجرایی ثبت شد.

## فاز 0: Baseline Hardening
### Milestone M0-1 امنیت پایه
- **T-SEC-001** — تعریف baseline secret/dependency policy
  - نقش‌ها: Security, DevOps/SRE
  - وابستگی: ندارد
  - پذیرش: CI امنیتی قابل رهگیری + artifact

### Milestone M0-2 حداقل‌های CI
- **T-CI-001** — حذف placeholder از job اصلی CI
  - نقش‌ها: DevOps/SRE, QA
  - وابستگی: T-SEC-001
  - پذیرش: اجرای واقعی lint/test

## فاز 1: Testing Uplift
### Milestone M1-1 پوشش تست
- **T-QA-001** — قراردادن آستانه پوشش و گزارش CI
  - نقش‌ها: QA, Backend
  - وابستگی: T-CI-001

## فاز 2: Performance/Observability
### Milestone M2-1
- **T-OBS-001** — افزودن متریک زمان اجرا/خطا در jobهای گزارش
  - نقش‌ها: DevOps/SRE, Product/UX

## فاز 3: Architecture/Standardization
### Milestone M3-1
- **T-ARC-001** — سیاست یکپارچه نسخه‌گذاری و branch protection در کل سازمان
  - نقش‌ها: Architect, Security, DevOps/SRE

## فاز 4: Delivery
### Milestone M4-1
- **T-REL-001** — reproducible local build + Docker parity
  - نقش‌ها: DevOps/SRE, QA

## اجرای خودکار انجام‌شده در این ران
- ایجاد ساختار مستندات audit و داشبورد محلی.
- استخراج inventory محلی.
- تلاش برای inventory GitHub org (ناموفق به علت نبود `gh`).
