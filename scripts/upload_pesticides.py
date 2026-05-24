"""
TPRI Tanzania Registered Pesticides Upload Script
Reads Tanzania_Registered_Pesticides_2011.xlsx and uploads all 208 records to Supabase.
"""

import sys, os, warnings, time
warnings.filterwarnings('ignore')
sys.path.insert(0, os.path.dirname(__file__))

import pandas as pd
from config import supabase, log

EXCEL_PATH = "/Users/deusjohn/Documents/Shamba smart/assets/data/Tanzania_Registered_Pesticides_2011.xlsx"
SHEET_NAME = "All Pesticides"

# ── Category → pesticide_type mapping ────────────────────────────────────────
TYPE_MAP = {
    '1a: insecticides':            'insecticide',
    '1b: herbicides':              'herbicide',
    '3a: fungicides':              'fungicide',
    '4a: acaricides':              'acaricide',
    '1e: plant growth regulators': 'plant_growth_regulator',
    '1f: rodenticides':            'rodenticide',
    '1g: avicides':                'avicide',
    '1h: nematicides':             'nematicide',
    '3c: restricted herbicides':   'restricted_herbicide',
}

# ── Swahili translations ──────────────────────────────────────────────────────
TYPE_SW = {
    'insecticide':            'Dawa ya Wadudu',
    'herbicide':              'Dawa ya Magugu',
    'fungicide':              'Dawa ya Kuvu',
    'acaricide':              'Dawa ya Utitiri',
    'plant_growth_regulator': 'Dawa ya Ukuaji',
    'rodenticide':            'Dawa ya Panya',
    'avicide':                'Dawa ya Ndege',
    'nematicide':             'Dawa ya Minyoo',
    'restricted_herbicide':   'Dawa ya Magugu (Marufuku)',
}

# ── Crop keyword extraction ───────────────────────────────────────────────────
CROP_KEYWORDS = {
    'maize':         ['maize', 'corn'],
    'tomato':        ['tomato'],
    'beans':         ['bean'],
    'cotton':        ['cotton'],
    'coffee':        ['coffee'],
    'tobacco':       ['tobacco'],
    'wheat':         ['wheat'],
    'rice':          ['rice'],
    'cashew':        ['cashew'],
    'banana':        ['banana'],
    'cassava':       ['cassava'],
    'horticultural_crops': ['horticultural', 'horticulture'],
    'stored_grain':  ['stored grain', 'stored product', 'silo'],
    'public_health': ['mosquito', 'housefl', 'fly', 'flies', 'rodent', 'rat', 'bird', 'quelea'],
    'sugarcane':     ['sugarcane', 'sugar cane'],
    'flowers':       ['rose', 'flower', 'chrysanthemum'],
    'vegetables':    ['vegetable', 'brassica', 'cabbage', 'kale'],
}

def extract_crops(usage_text):
    """Extract crop names from usage/target pest text."""
    if not usage_text or pd.isna(usage_text):
        return []
    text = str(usage_text).lower()
    crops = []
    for crop, keywords in CROP_KEYWORDS.items():
        for kw in keywords:
            if kw in text:
                crops.append(crop)
                break
    return crops if crops else ['general']

def clean(val):
    """Strip whitespace and return None for NaN."""
    if pd.isna(val) if hasattr(val, '__class__') and val.__class__.__name__ in ('float',) else False:
        return None
    s = str(val).strip()
    return s if s and s.lower() not in ('nan', 'none', '') else None

def process_row(row):
    """Convert one Excel row to a Supabase-ready dict."""
    trade_name    = clean(row.get('Trade Name'))
    active_ing    = clean(row.get('Common Name / Active Ingredient'))
    reg_no        = clean(row.get('Reg. No.'))
    registrant    = clean(row.get('Registrant'))
    usage         = clean(row.get('Usage / Target Pest'))
    category      = clean(row.get('Category'))
    sub_cat       = clean(row.get('Sub-category'))

    if not trade_name:
        return None  # skip blank rows

    sub_cat_lower  = (sub_cat or '').lower()
    pesticide_type = TYPE_MAP.get(sub_cat_lower, 'other')
    type_sw        = TYPE_SW.get(pesticide_type, 'Dawa ya Kilimo')
    is_restricted  = (category or '').strip().lower() == 'restricted registration'
    crops          = extract_crops(usage)

    return {
        # ── Existing columns (work with current table schema) ──────
        'brand_name':        trade_name,
        'active_ingredient': active_ing,
        'manufacturer':      registrant,
        'category':          pesticide_type,   # store type value in category column
        'description_sw':    usage,
        'target_crops':      crops,
        'tpri_registered':   True,
    }

def get_existing_brand_names():
    """Fetch all brand_names already in Supabase to detect duplicates."""
    try:
        res = supabase.table("pesticides") \
            .select("brand_name") \
            .execute()
        return {r['brand_name'].strip().lower() for r in res.data if r.get('brand_name')}
    except Exception as e:
        log.warning(f"Could not fetch existing records: {e}")
        return set()

def run():
    print("\n" + "="*60)
    print("  TPRI PESTICIDES UPLOAD — Tanzania 2011 Registry")
    print("="*60)

    # ── 1. Read Excel ─────────────────────────────────────────────
    print(f"\n▶ Reading Excel file...")
    df = pd.read_excel(EXCEL_PATH, sheet_name=SHEET_NAME, header=0)
    print(f"  Found {len(df)} rows in '{SHEET_NAME}' sheet")
    print(f"  Columns: {list(df.columns)}")

    # ── 2. Process all rows ───────────────────────────────────────
    print("\n▶ Processing rows...")
    records = []
    for _, row in df.iterrows():
        rec = process_row(row)
        if rec:
            records.append(rec)
    print(f"  {len(records)} valid records ready for upload")

    # ── 3. Check existing data ────────────────────────────────────
    print("\n▶ Checking for existing records in Supabase...")
    existing = get_existing_brand_names()
    print(f"  {len(existing)} records already in database")

    # ── 4. Upload in batches ──────────────────────────────────────
    print("\n▶ Uploading to Supabase (batches of 50)...")
    uploaded = 0
    skipped  = 0
    failed   = 0
    failed_names = []

    BATCH = 50
    to_insert = []
    for rec in records:
        name = (rec.get('brand_name') or '').strip().lower()
        if name and name in existing:
            skipped += 1
        else:
            to_insert.append(rec)

    print(f"  Skipping {skipped} duplicates — uploading {len(to_insert)} new records")

    for i in range(0, len(to_insert), BATCH):
        batch = to_insert[i:i + BATCH]
        try:
            supabase.table("pesticides").insert(batch).execute()
            uploaded += len(batch)
            print(f"  Uploaded {uploaded}/{len(to_insert)} pesticides...")
        except Exception as e:
            err = str(e)
            log.warning(f"Batch {i//BATCH+1} failed: {err[:100]}")
            # Retry individually
            for rec in batch:
                try:
                    supabase.table("pesticides").insert(rec).execute()
                    uploaded += 1
                except Exception as e2:
                    failed += 1
                    failed_names.append(rec.get('brand_name', '?'))
                    log.warning(f"  ✗ Failed: {rec.get('brand_name')} — {str(e2)[:80]}")
        time.sleep(0.3)

    # ── 5. Summary ────────────────────────────────────────────────
    print("\n" + "="*60)
    print("  UPLOAD COMPLETE")
    print("="*60)
    print(f"  ✓ Successfully uploaded : {uploaded} records")
    print(f"  ⚠ Duplicates skipped   : {skipped} records")
    print(f"  ✗ Failed                : {failed} records")
    if failed_names:
        print(f"  Failed items: {', '.join(failed_names[:10])}")

    # ── 6. Verification ───────────────────────────────────────────
    print("\n▶ Verification — querying Supabase...")
    try:
        total = supabase.table("pesticides").select("id", count="exact").execute()
        print(f"  Total pesticides in Supabase: {total.count}")

        by_type = supabase.table("pesticides") \
            .select("pesticide_type") \
            .execute()
        from collections import Counter
        counts = Counter(r['pesticide_type'] for r in by_type.data if r.get('pesticide_type'))
        print("\n  Breakdown by type:")
        for t, c in counts.most_common():
            print(f"    {t:<30} {c:>4} records")
    except Exception as e:
        print(f"  Verification query error: {e}")

    print("\n  ✅ Check Supabase dashboard: supabase.com")
    print("="*60 + "\n")

if __name__ == "__main__":
    run()
