# وضعیت تست

## وضعیت فعلی
- `tests/test_scripts.sh` تعداد زیادی تست bash را اجرا می‌کند.
- Make target `test` مسیر validate + test suite را اجرا می‌کند.
- `verify` تمام گیت‌ها (lint/typecheck/test/e2e/build/security/coverage) را زنجیره‌ای اجرا می‌کند.

## شکاف‌ها
- e2e فقط در صورت وجود `scripts/run-e2e.sh` فعال می‌شود.
- coverage target تعریف شده ولی معیار coverage برای زبان/ماژول‌ها شفاف‌سازی می‌خواهد.
