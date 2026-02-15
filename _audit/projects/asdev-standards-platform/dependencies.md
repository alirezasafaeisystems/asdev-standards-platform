# وابستگی‌ها

## ابزارهای کلیدی
- Bash (اجرای اصلی اتوماسیون)
- GNU Make (ارکستراسیون)
- Python 3 (اسکریپت‌های کمکی)
- gh CLI (برای تعاملات GitHub)
- yq (validation/processing)

## ریسک وابستگی
- نبود `gh` در محیط باعث شکست inventory سازمان GitHub شد (ثبت در `errors.log`).
- وجود guard در Makefile برای setup، اما در برخی مسیرها fallback کامل وجود ندارد.
