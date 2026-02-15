# عملکرد و کارایی

## مشاهدات
- اکثر pipelineها shell-based هستند و سربار runtime پایین دارند.
- job زمان‌بندی‌شده تولید گزارش ممکن است با clone چند repo کند شود.

## ریسک‌های کارایی
- `fetch-depth: 0` در CI برای چند job هزینه شبکه/زمان را بالا می‌برد.
- اجرای سریال مراحل verification زمان feedback را افزایش می‌دهد.

## پیشنهاد
- کش ابزارها و artifact reuse بیشتر.
- parallelization محدود برای test suites مستقل.
