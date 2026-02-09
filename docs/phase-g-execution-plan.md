# برنامه اجرایی Phase G

این برنامه، تسک‌های باقی‌مانده را از `docs/phase-b-next-steps.md` به یک ترتیب اجرایی عملیاتی تبدیل می‌کند.

## 1) رفع بلاکر زیرساخت GitHub و اجرای پایلوت Go (اولویت خیلی بالا)
- **Task ID:** G1
- **وابستگی:** ندارد (ولی پیش‌نیاز بخشی از G2)
- **خروجی مورد انتظار:**
  - ساخت یا آماده‌سازی Go pilot repo
  - اجرای اولین PR همگام‌سازی Level 1 Go
  - ثبت لینک PR در یادداشت governance
- **Definition of Done:**
  - PR ساخته شده و حداقل یک بار CI پاس شده باشد.

## 2) اجرای دستی Weekly Governance Digest و اعتبارسنجی خروجی (اولویت بالا)
- **Task ID:** G2
- **وابستگی:** بهتر است بعد از G1 انجام شود تا وضعیت جدید در Digest منعکس شود.
- **دستور اجرا:**
  - `bash scripts/weekly-governance-digest.sh`
- **خروجی مورد انتظار:**
  - ایجاد/آپدیت Issue هفتگی governance
  - بررسی وجود بخش divergence delta در متن issue
- **Definition of Done:**
  - Issue ایجاد یا آپدیت شده و محتوای آن با داده‌های dashboard هم‌خوان باشد.

## 3) افزودن بخش Trend برای Combined Report در Dashboard (اولویت متوسط)
- **Task ID:** G3
- **وابستگی:** خروجی `sync/divergence-report.combined.csv`
- **خروجی مورد انتظار:**
  - نمایش delta نسبت به snapshot قبلی در dashboard
  - نمایش تغییرات per-repo یا per-template به‌صورت خلاصه
- **Definition of Done:**
  - `docs/platform-adoption-dashboard.md` شامل سکشن trend برای combined report باشد.

## 4) افزودن Retry/Backoff سبک برای اسکریپت‌های وابسته به GitHub API (اولویت متوسط)
- **Task ID:** G4
- **وابستگی:** ندارد
- **دامنه:**
  - `platform/scripts/sync.sh`
  - `platform/scripts/divergence-report.sh`
  - در صورت نیاز `platform/scripts/divergence-report-combined.sh`
- **خروجی مورد انتظار:**
  - Retry با تعداد محدود (مثلاً 3 بار)
  - Backoff افزایشی ساده (مثلاً 2s، 4s، 8s)
  - لاگ شفاف برای خطاهای transient
- **Definition of Done:**
  - در خطاهای موقت شبکه، اسکریپت قبل از fail نهایی retry کند و خروجی قابل رهگیری داشته باشد.

## 5) افزودن Runbook مدیریت اختلال و بازیابی در docs (اولویت متوسط)
- **Task ID:** G5
- **وابستگی:** بهتر است پس از G4 انجام شود تا رفتار retry/backoff مستندسازی شود.
- **خروجی مورد انتظار:**
  - سند runbook با سناریوهای outage رایج GitHub API
  - مراحل triage، rollback، re-run، و معیار پایان incident
- **Definition of Done:**
  - یک سند جدید در `docs/` با چک‌لیست اجرایی incident response اضافه شود.

## ترتیب اجرای پیشنهادی
1. G1
2. G2
3. G3
4. G4
5. G5

## چک‌لیست وضعیت فعلی
- [ ] G1 انجام نشده (مسدود: GitHub API TLS handshake timeout)
- [ ] G2 انجام نشده (مسدود: GitHub API TLS handshake timeout)
- [x] G3 انجام شده
- [x] G4 انجام شده
- [x] G5 انجام شده
