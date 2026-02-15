# DevOps / CI-CD

## وضعیت
- CI روی push/pr/schedule فعال است.
- workflow جداگانه برای generate گزارش و PR خودکار وجود دارد.
- concurrency برای جلوگیری از اجراهای موازی conflictدار فعال است.

## شکاف‌ها
- job `lint-and-test` فعلاً minimal placeholder دارد و همه گیت‌های واقعی را اجرا نمی‌کند.
- نیاز به سیاست یکسان برای required checks در همه ریپوهای وابسته.
