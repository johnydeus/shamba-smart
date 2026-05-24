"""
Query all Shamba Smart tables and print a summary report.
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from config import supabase, log

TABLES = [
    ("pesticides",    "brand_name",    "TPHPA"),
    ("seed_varieties","variety_name",  "TOSCI"),
    ("research_data", "title",         "TPRI"),
    ("fertilisers",   "product_name",  "Yara TZ"),
    ("agro_products", "product_name",  "Balton TZ"),
    ("market_prices", "crop_name",     "kilimo.go.tz"),
    ("agrovets",      "shop_name",     "Directories"),
    ("scrape_logs",   "target_name",   "System"),
]

def run_report():
    total = 0
    print("\n" + "="*52)
    print("  SHAMBA SMART DATA PIPELINE — REPORT")
    print("="*52)

    for table, col, source in TABLES:
        try:
            res = supabase.table(table).select(col, count="exact").execute()
            count = res.count if res.count is not None else len(res.data)
            flag = "⚠ EMPTY" if count == 0 else "✓"
            print(f"  {flag} {table:<18} {count:>5} records  (source: {source})")
            total += count
        except Exception as e:
            print(f"  ✗ {table:<18} ERROR — {e}")

    print("-"*52)
    print(f"  Total records in Supabase: {total}")
    print("="*52)

    # Last scrape times
    try:
        logs = supabase.table("scrape_logs").select("*").order("started_at", desc=True).limit(10).execute()
        if logs.data:
            print("\n  Recent scrape runs:")
            for r in logs.data:
                print(f"    {r['target_name']:<30} {r['status']:<10} {r.get('records_scraped',0)} records")
    except Exception:
        pass

    print("\n  Check your Supabase dashboard at supabase.com")
    print("  All tables should now have data.\n")

if __name__ == "__main__":
    run_report()
