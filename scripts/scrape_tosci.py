#!/usr/bin/env python3
"""Scrape the full TOSCI seed variety registry (https://www.tosci.go.tz/seed-varieties).

Output: scripts/tosci_varieties_raw.json — one record per variety with all
label/value pairs found on each detail page.
"""
import json
import re
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed

BASE = "https://www.tosci.go.tz/seed-varieties"
HEADERS = {"User-Agent": "Mozilla/5.0 (ShambaSmart data sync)"}
OUT = "scripts/tosci_varieties_raw.json"

DETAIL_LINK_RE = re.compile(r'href="(https://www\.tosci\.go\.tz/seed-varieties/[^"?]+)"')
FIELD_RE = re.compile(
    r'<div class="faded text-capitalize">\s*(.*?)\s*</div>\s*'
    r'<div class="text-dark mt-0">\s*(.*?)\s*</div>',
    re.S,
)
TAG_RE = re.compile(r"<[^>]+>")


def fetch(url, retries=3):
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.read().decode("utf-8", errors="replace")
        except Exception as e:
            if attempt == retries - 1:
                print(f"FAILED {url}: {e}", file=sys.stderr)
                return None
            time.sleep(2 * (attempt + 1))


def clean(text):
    text = TAG_RE.sub(" ", text)
    return re.sub(r"\s+", " ", text).strip()


def collect_detail_urls():
    urls = set()
    page = 1
    while True:
        html = fetch(f"{BASE}?page={page}")
        if html is None:
            break
        found = set(DETAIL_LINK_RE.findall(html))
        new = found - urls
        if not new:
            break
        urls |= new
        print(f"page {page}: +{len(new)} (total {len(urls)})")
        page += 1
    return sorted(urls)


def scrape_detail(url):
    html = fetch(url)
    if html is None:
        return None
    fields = {}
    for label, value in FIELD_RE.findall(html):
        label = clean(label)
        value = clean(value)
        if label:
            fields[label] = value
    if not fields:
        return None
    fields["detail_url"] = url
    return fields


def main():
    urls = collect_detail_urls()
    print(f"Collected {len(urls)} variety URLs. Scraping details...")
    results = []
    with ThreadPoolExecutor(max_workers=12) as ex:
        futures = {ex.submit(scrape_detail, u): u for u in urls}
        done = 0
        for fut in as_completed(futures):
            rec = fut.result()
            done += 1
            if rec:
                results.append(rec)
            if done % 100 == 0:
                print(f"  {done}/{len(urls)} scraped")
    results.sort(key=lambda r: r.get("Jina", ""))
    with open(OUT, "w") as f:
        json.dump(results, f, ensure_ascii=False, indent=1)
    print(f"Wrote {len(results)} records to {OUT}")
    # Report which field labels exist across the registry
    labels = {}
    for r in results:
        for k in r:
            labels[k] = labels.get(k, 0) + 1
    print("Field coverage:")
    for k, v in sorted(labels.items(), key=lambda x: -x[1]):
        print(f"  {k}: {v}")


if __name__ == "__main__":
    main()
