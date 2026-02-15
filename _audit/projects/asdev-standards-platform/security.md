# وضعیت امنیت

## کنترل‌های موجود
- اسکن الگوهای secret با `scripts/security-audit.sh`.
- رد کردن کلیدهای رایج (AWS/GitHub token/private key) با severity بالا.
- enforce محدودیت فایل‌های تست برای false positive.

## شکاف‌ها
- Security scan فقط regex-محور است و SCA/CVE dependency-level را پوشش نمی‌دهد.
- نیاز به baseline policy برای branch protection و code scanning پیش‌فرض.

## توصیه
- افزودن dependency audit ساختاریافته (OSV/SBOM).
- افزودن secret scanning در CI با SARIF.
