#!/usr/bin/env python3
"""
seed_agrovets.py — Load REAL agrovet & agricultural-institution data into the
Supabase `agrovets` table (v2 schema) from official Tanzania sources.

⚠️ HONESTY / SAFETY RULES (do not violate):
  - This script loads ONLY real data pulled from the official sources below.
  - It NEVER fabricates shops, phone numbers, or locations.
  - Where a source cannot be scraped cleanly (JS-rendered, login-walled, PDF,
    or no structured listing), the function returns [] and prints a clear
    "MANUAL COLLECTION NEEDED" note so Amani/Deus can collect by hand.
  - Government-registered sources are marked is_verified=True; anything else
    stays is_verified=False until an officer confirms it in-app.

Sources (verify selectors against the live sites before a real run):
  - TFRA  fertilizer dealers .......... https://fis.tfra.go.tz
  - TPHPA pesticide retailers/.......... https://www.tphpa.go.tz  (Pesticides
          wholesalers/importers               Stock Management System)
  - TOSCI seed dealers ................. https://www.tosci.go.tz
  - NCD   commercial directory ......... https://www.ncd.co.tz
  - (optional) Google Places API ...... needs key in an Edge Function/secret;
          respect Google's terms; do not store beyond what's permitted.

Usage:
  export SUPABASE_URL=...           # project URL
  export SUPABASE_SERVICE_ROLE_KEY=...   # service role (server-side only!)
  python3 scripts/seed_agrovets.py --source tfra --dry-run
  python3 scripts/seed_agrovets.py --source all          # real upload

Install: pip install requests beautifulsoup4 supabase
"""

import argparse
import os
import sys

try:
    import requests
    from bs4 import BeautifulSoup  # noqa: F401  (used by per-source parsers)
except ImportError:
    print("Install deps: pip install requests beautifulsoup4 supabase")
    sys.exit(1)

CATEGORIES = [
    "fertilizer", "seeds", "pesticides", "crop_buying",
    "equipment", "veterinary", "advisory",
]

TIMEOUT = 30


def manual_note(source: str, reason: str):
    print(f"  ⚠️  MANUAL COLLECTION NEEDED [{source}]: {reason}")
    print(f"      → collect real entries by hand and load via --source manual_csv")


# ── TFRA — fertilizer dealers ────────────────────────────────────────────────
def fetch_tfra() -> list[dict]:
    """TFRA Fertilizer Information System (fis.tfra.go.tz).

    The public dealer directory is rendered behind a search form / data table.
    Verify whether it exposes a JSON endpoint (DevTools → Network) or a plain
    HTML table before trusting selectors. Until verified on the live site, do
    NOT guess — flag for manual collection.
    """
    out: list[dict] = []
    try:
        r = requests.get("https://fis.tfra.go.tz", timeout=TIMEOUT)
        r.raise_for_status()
        # TODO(verify-live): locate the dealers table / API endpoint and parse:
        #   name, region, district, phone -> append real rows below.
        #   Each row: _row(name, "government", ["fertilizer"], region, ...,
        #                   source="TFRA", verified=True)
        manual_note("TFRA", "dealer directory structure not yet verified on live site")
    except Exception as e:
        manual_note("TFRA", f"request failed: {e}")
    return out


# ── TPHPA — pesticide retailers / wholesalers / importers ────────────────────
def fetch_tphpa() -> list[dict]:
    """TPHPA Pesticides Stock Management System (tphpa.go.tz).

    Registered dealers are typically published as PDF gazettes or in a portal.
    PDFs need a parser (pdfplumber) and careful column mapping. Flag for manual
    until the exact document/endpoint is confirmed.
    """
    out: list[dict] = []
    manual_note("TPHPA", "dealer list usually in PDF/portal — confirm format, then parse")
    return out


# ── TOSCI — seed dealers ─────────────────────────────────────────────────────
def fetch_tosci() -> list[dict]:
    """TOSCI seed dealers (tosci.go.tz). NOTE: use www.tosci.go.tz, not bare domain."""
    out: list[dict] = []
    try:
        r = requests.get("https://www.tosci.go.tz", timeout=TIMEOUT)
        r.raise_for_status()
        # TODO(verify-live): find the registered seed-dealer listing and parse.
        manual_note("TOSCI", "seed-dealer listing page not yet verified")
    except Exception as e:
        manual_note("TOSCI", f"request failed: {e}")
    return out


# ── NCD — commercial directory ───────────────────────────────────────────────
def fetch_ncd() -> list[dict]:
    """NCD commercial directory (ncd.co.tz) agrovet listings."""
    out: list[dict] = []
    manual_note("NCD", "directory may be paginated/JS — confirm before scraping")
    return out


def _row(name, type_, categories, region, *, district=None, ward=None,
         phone=None, source="self-registered", verified=False, **extra):
    """Build a clean agrovets row. Only call with REAL data."""
    assert name and region, "name and region are required — never blank"
    assert all(c in CATEGORIES for c in categories), "invalid category"
    row = {
        "name": name, "type": type_, "categories": categories,
        "region": region, "district": district, "ward": ward,
        "phone": phone, "is_verified": verified,
        "is_self_registered": False, "source": source,
    }
    row.update(extra)
    return row


SOURCES = {
    "tfra": fetch_tfra, "tphpa": fetch_tphpa,
    "tosci": fetch_tosci, "ncd": fetch_ncd,
}


def upload(rows: list[dict], dry_run: bool):
    if not rows:
        print("\nNo real rows gathered. Nothing uploaded (this is correct — we "
              "never fabricate). Use the MANUAL COLLECTION notes above.")
        return
    if dry_run:
        print(f"\n[dry-run] would upload {len(rows)} real rows.")
        for r in rows[:5]:
            print("  ", r["name"], "—", r["region"], r["categories"])
        return
    from supabase import create_client
    url, key = os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        print("Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY env vars.")
        sys.exit(1)
    sb = create_client(url, key)
    sb.table("agrovets").insert(rows).execute()
    print(f"\n✅ Uploaded {len(rows)} verified rows.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", default="all", choices=[*SOURCES, "all"])
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    picked = SOURCES.keys() if args.source == "all" else [args.source]
    rows: list[dict] = []
    for s in picked:
        print(f"\n→ {s.upper()}")
        rows.extend(SOURCES[s]())
    upload(rows, args.dry_run)


if __name__ == "__main__":
    main()
