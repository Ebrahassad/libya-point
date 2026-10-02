#!/usr/bin/env python3
"""فحص وصحة محتوى روابط Libya Point.

يفحص:
- الروابط الحرفية في ملفات الدليل والمحتوى.
- روابط المصدر ومصادر الأخبار.
- تكرار المعرفات الثابتة في بيانات الدليل والتطبيقات.

الاستخدام:
    python3 tools/check_links.py
    python3 tools/check_links.py --no-network

ملاحظة: بعض المواقع الحكومية/المصرفية قد تمنع طلبات HEAD أو الروبوتات؛ لذلك 401/403/405/429
تُعرض كتحذير، بينما 404/410 وأخطاء الاتصال تُعرض كأخطاء.
"""
import argparse
import re
import ssl
import sys
import urllib.error
import urllib.request
from collections import Counter
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FILES = [
    ROOT / "lib/data/directory.dart",
    ROOT / "lib/data/apps_data.dart",
    ROOT / "lib/data/hotels.dart",
    ROOT / "lib/data/news_sources.dart",
    ROOT / "content/content.json",
    ROOT / "content/example_full.json",
    ROOT / "lib/services/live_data.dart",
]
URL_RE = re.compile(r"https?://[^\s'\"$]+")
ID_RE = re.compile(r"\bid:\s*'([^']+)'|\"id\"\s*:\s*\"([^\"]+)\"")
SKIP_PREFIXES = (
    "https://play.google.com/store/apps/search",
    "https://play.google.com/store/search",
    "https://www.google.com/maps/search",
    "https://www.google.com/search?q=${",
    "https://www.google.com/search?",
    "https://tile.openstreetmap.org",
    "https://api.open-meteo.com",
    "https://api.oilpriceapi.com",
    "https://news.google.com/rss",
    "https://api.aladhan.com",
    "https://api.gold-api.com",
)
SOFT = {401, 403, 405, 429, 999}
HEADERS = {"User-Agent": "Mozilla/5.0 (LibyaPoint link checker)", "Accept-Language": "ar,en"}


def collect_urls():
    urls = {}
    for f in FILES:
        if not f.exists():
            continue
        for lineno, line in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            for m in URL_RE.finditer(line):
                u = m.group(0).rstrip(",);]}")
                if any(u.startswith(p) for p in SKIP_PREFIXES) or "${" in u:
                    continue
                urls.setdefault(u, f"{f.relative_to(ROOT)}:{lineno}")
    return urls


def duplicate_ids():
    ids = []
    for f in [ROOT / "lib/data/directory.dart", ROOT / "lib/data/apps_data.dart", ROOT / "content/content.json"]:
        if not f.exists():
            continue
        for line in f.read_text(encoding="utf-8").splitlines():
            for m in ID_RE.finditer(line):
                ids.append((m.group(1) or m.group(2), str(f.relative_to(ROOT))))
    counter = Counter(x[0] for x in ids)
    return {k: [src for ident, src in ids if ident == k] for k, v in counter.items() if v > 1}


def check(url):
    ctx = ssl.create_default_context()
    for method in ("HEAD", "GET"):
        req = urllib.request.Request(url, method=method, headers=HEADERS)
        try:
            with urllib.request.urlopen(req, timeout=8, context=ctx) as r:
                return url, r.status, None
        except urllib.error.HTTPError as e:
            if method == "HEAD" and e.code in SOFT | {400, 404, 405, 501}:
                continue
            return url, e.code, None
        except Exception as e:
            if method == "HEAD":
                continue
            return url, None, str(e)
    return url, None, "unknown"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--no-network", action="store_true")
    args = parser.parse_args()

    dup = duplicate_ids()
    if dup:
        print("تكرار IDs:")
        for ident, sources in sorted(dup.items()):
            print(f"  DUP  {ident}: {', '.join(sources)}")
    else:
        print("IDs: OK")

    urls = collect_urls()
    print(f"روابط حرفية قابلة للفحص: {len(urls)}")
    if args.no_network:
        print("تم تجاوز فحص الشبكة (--no-network).")
        return 1 if dup else 0

    bad, warn = [], []
    with ThreadPoolExecutor(max_workers=8) as ex:
        for url, status, err in ex.map(check, urls):
            where = urls[url]
            if status is not None and 200 <= status < 400:
                print(f"  OK   {status}  {url}")
            elif status in SOFT:
                warn.append((url, status, where))
                print(f"  WARN {status}  {url}   ({where})")
            else:
                bad.append((url, status or err, where))
                print(f"  FAIL {status or err}  {url}   ({where})")
    print(f"\nسليم: {len(urls) - len(bad) - len(warn)} | تحذير: {len(warn)} | معطوب: {len(bad)}")
    return 1 if bad or dup else 0


if __name__ == "__main__":
    sys.exit(main())
