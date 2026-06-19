#!/usr/bin/env python3
"""
update_pesticides_2026.py — Refresh pesticide approval status against the
CURRENT TPHPA list (post Jan-2026 purge that withdrew 675+ products and flagged
130 as Highly Hazardous).

⚠️ SAFETY RULES (do not violate):
  - This script NEVER guesses approval status. A product is marked 'approved'
    ONLY if it appears on the verified current TPHPA approved register.
  - Products NOT on the current approved list are marked 'withdrawn' so the app
    never recommends them. Products on the HHP list are marked 'hhp'.
  - If the current list cannot be fetched/parsed cleanly, the script makes NO
    changes and prints a clear "MANUAL UPDATE NEEDED" note. We would rather
    leave everything 'unknown' (and recommend nothing) than guess.

Status model (matches scripts/pesticides_approval_migration.sql):
  approved | withdrawn | hhp | unknown

Source: TPHPA (tphpa.go.tz) — the registered/approved pesticides register and
the withdrawn / Highly Hazardous lists. These are usually published as PDF
gazettes; confirm the exact current document before a real run.

Usage:
  export SUPABASE_URL=...
  export SUPABASE_SERVICE_ROLE_KEY=...
  python3 scripts/update_pesticides_2026.py --dry-run
  python3 scripts/update_pesticides_2026.py            # apply

Install: pip install requests pdfplumber supabase
"""

import os
import sys
import argparse

try:
    import requests  # noqa: F401
except ImportError:
    print("Install deps: pip install requests pdfplumber supabase")
    sys.exit(1)

TIMEOUT = 30


def fetch_current_tphpa_lists() -> dict[str, set[str]] | None:
    """Return {'approved': {...brand names...}, 'hhp': {...}} from the CURRENT
    TPHPA register, or None if it can't be parsed cleanly.

    TPHPA publishes these as PDFs. Parsing a PDF table reliably requires
    confirming the current file URL and column layout. Until that's verified on
    the live site, return None so NOTHING is guessed.
    """
    try:
        # TODO(verify-live): set the current approved-register + HHP PDF URLs,
        # download, parse with pdfplumber, and build the brand-name sets.
        #   approved = {normalize(name) for name in approved_table_rows}
        #   hhp      = {normalize(name) for name in hhp_table_rows}
        #   return {"approved": approved, "hhp": hhp}
        print("⚠️  MANUAL UPDATE NEEDED [TPHPA]: confirm the current approved-"
              "register + HHP PDF URLs and column layout, then implement the "
              "pdfplumber parse. No status changes made (safe default).")
        return None
    except Exception as e:
        print(f"⚠️  MANUAL UPDATE NEEDED [TPHPA]: fetch/parse failed: {e}")
        return None


def normalize(name: str) -> str:
    return " ".join(name.strip().lower().split())


def apply_statuses(lists: dict[str, set[str]], dry_run: bool):
    from supabase import create_client
    url, key = os.environ.get("SUPABASE_URL"), os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        print("Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY env vars.")
        sys.exit(1)
    sb = create_client(url, key)

    rows = sb.table("pesticides").select("id,brand_name").execute().data
    approved, hhp = lists["approved"], lists.get("hhp", set())
    counts = {"approved": 0, "hhp": 0, "withdrawn": 0}

    for row in rows:
        nm = normalize(row["brand_name"])
        if nm in hhp:
            status = "hhp"
        elif nm in approved:
            status = "approved"
        else:
            status = "withdrawn"  # not on current approved list → never recommend
        counts[status] += 1
        if not dry_run:
            sb.table("pesticides").update({
                "approval_status": status,
                "last_verified_date": "2026-01-01",  # set to the register's date
                "status_source": "TPHPA",
            }).eq("id", row["id"]).execute()

    print(f"\n{'[dry-run] ' if dry_run else ''}Result: "
          f"{counts['approved']} approved, {counts['hhp']} HHP, "
          f"{counts['withdrawn']} withdrawn (of {len(rows)} total).")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    lists = fetch_current_tphpa_lists()
    if lists is None:
        print("\nNo verified TPHPA list available → leaving all statuses as-is "
              "('unknown'). The app recommends nothing until real approved data "
              "is loaded. This is the safe outcome.")
        return
    apply_statuses(lists, args.dry_run)


if __name__ == "__main__":
    main()
