"""
Upload TOSCI detailed variety data to Supabase seed_varieties table.
Reads: scripts/output/tosci_varieties_detailed.json
Upserts on variety_name (updates existing rows with new columns).

Run AFTER:
  1. migrate_seed_varieties_detailed.sql executed in Supabase SQL Editor
  2. scrape_tosci_detailed.py completed
"""
from __future__ import annotations
import sys, os, json, time, re
sys.path.insert(0, os.path.dirname(__file__))
from config import supabase, log

DETAIL_JSON = os.path.join(os.path.dirname(__file__), "output", "tosci_varieties_detailed.json")

CROP_SW_TO_EN = {
    "mahindi": "maize",        "mpunga": "rice",          "mchele": "rice",
    "ngano": "wheat",          "mtama": "sorghum",        "uwele": "millet",
    "ulezi": "finger millet",  "shayiri": "barley",       "maharagwe": "beans",
    "choroko": "cowpea",       "karanga": "groundnut",    "soya": "soybean",
    "mbaazi": "pigeon pea",    "nyanya": "tomato",        "kabichi": "cabbage",
    "sukuma wiki": "kale",     "vitunguu": "onion",       "pilipili": "pepper",
    "karoti": "carrot",        "bamia": "okra",           "tango": "cucumber",
    "mchicha": "spinach",      "tikiti maji": "watermelon",
    "muhogo": "cassava",       "viazi vitamu": "sweet potato",
    "viazi": "potato",         "ndizi": "banana",         "embe": "mango",
    "papai": "papaya",         "nanasi": "pineapple",     "parachichi": "avocado",
    "pamba": "cotton",         "alizeti": "sunflower",    "kahawa": "coffee",
    "chai": "tea",             "korosho": "cashew",       "miwa": "sugarcane",
    "tumbaku": "tobacco",      "ufuta": "sesame",
}

SCIENTIFIC_TO_EN = {
    "zea mays": "maize",               "oryza sativa": "rice",
    "manihot": "cassava",              "solanum lycopersicum": "tomato",
    "lycopersicon": "tomato",          "phaseolus vulgaris": "beans",
    "vigna": "cowpea",                 "cajanus cajan": "pigeon pea",
    "hordeum vulgare": "barley",       "triticum": "wheat",
    "sorghum bicolor": "sorghum",      "helianthus annu": "sunflower",
    "gossypium": "cotton",             "arachis hypogaea": "groundnut",
    "glycine max": "soybean",          "anacardium occidentale": "cashew",
    "coffea": "coffee",                "camellia sinensis": "tea",
    "musa": "banana",                  "solanum tuberosum": "potato",
    "ipomoea batatas": "sweet potato", "allium cepa": "onion",
    "capsicum": "pepper",              "brassica oleracea": "cabbage",
    "brassica": "kale",                "daucus carota": "carrot",
    "mangifera indica": "mango",       "carica papaya": "papaya",
    "ananas comosus": "pineapple",     "persea americana": "avocado",
    "sesamum indicum": "sesame",       "nicotiana tabacum": "tobacco",
    "saccharum officinarum": "sugarcane", "pennisetum": "millet",
    "eleusine coracana": "finger millet", "citrullus lanatus": "watermelon",
    "cucumis melo": "melon",           "cucumis sativus": "cucumber",
    "abelmoschus esculentus": "okra",  "spinacia": "spinach",
    "pisum sativum": "peas",
}

CROP_SW_LABELS = {
    "maize": "Mahindi",        "rice": "Mchele/Mpunga",   "wheat": "Ngano",
    "sorghum": "Mtama",        "millet": "Uwele",          "finger millet": "Ulezi",
    "barley": "Shayiri",       "beans": "Maharagwe",       "cowpea": "Choroko",
    "groundnut": "Karanga",    "soybean": "Soya",          "pigeon pea": "Mbaazi",
    "tomato": "Nyanya",        "cabbage": "Kabichi",       "kale": "Sukuma Wiki",
    "onion": "Vitunguu",       "pepper": "Pilipili",       "carrot": "Karoti",
    "okra": "Bamia",           "cucumber": "Tango",        "spinach": "Mchicha",
    "watermelon": "Tikiti Maji","cassava": "Muhogo",       "sweet potato": "Viazi Vitamu",
    "potato": "Viazi",         "banana": "Ndizi",          "mango": "Embe",
    "papaya": "Papai",         "pineapple": "Nanasi",      "avocado": "Parachichi",
    "cotton": "Pamba",         "sunflower": "Alizeti",     "coffee": "Kahawa",
    "tea": "Chai",             "cashew": "Korosho",        "sugarcane": "Miwa",
    "tobacco": "Tumbaku",      "sesame": "Ufuta",          "peas": "Mbaazi Ndogo",
}


def resolve_crop_en(detail: dict) -> tuple[str, str]:
    """Return (crop_type_en, crop_type_sw) from detail record."""
    # Try scientific name
    sci = (detail.get("crop_scientific") or "").lower()
    if sci:
        for prefix, en in SCIENTIFIC_TO_EN.items():
            if prefix in sci:
                return en, CROP_SW_LABELS.get(en, en.title())

    # Try common name (Swahili or English)
    common = (detail.get("crop_common") or "").lower().strip()
    if common:
        if common in CROP_SW_TO_EN:
            en = CROP_SW_TO_EN[common]
            return en, CROP_SW_LABELS.get(en, en.title())
        # Direct English match
        for en in CROP_SW_LABELS:
            if en in common:
                return en, CROP_SW_LABELS[en]

    # Try full name
    full = (detail.get("zao") or detail.get("crop_full_name") or "").lower()
    if full:
        for prefix, en in SCIENTIFIC_TO_EN.items():
            if prefix in full:
                return en, CROP_SW_LABELS.get(en, en.title())
        for sw, en in CROP_SW_TO_EN.items():
            if sw in full:
                return en, CROP_SW_LABELS.get(en, en.title())

    return (common or "other"), (detail.get("crop_common") or "Nyingine")


def build_row(d: dict, existing_cols: set[str]) -> dict:
    """Convert a detail dict into a Supabase upsert row.
    Maps new scraped fields to existing DB columns + any new columns if migration ran.
    """
    crop_en, crop_sw = resolve_crop_en(d)

    # Suitable regions: list from scraper
    regions = d.get("suitable_regions")
    if isinstance(regions, str):
        regions = [r.strip() for r in regions.split(",") if r.strip()]
    regions = regions or []

    # Registration year as int
    yr_raw = d.get("mwaka_usajili")
    reg_year = None
    if yr_raw:
        m = re.search(r'\b(19|20)\d{2}\b', str(yr_raw))
        if m:
            reg_year = int(m.group())

    # Grain yield t/ha → kg/acre for existing yield_kg_per_acre column
    # 1 t/ha = 404.686 kg/acre
    yield_kg_acre = None
    gmin = d.get("grain_yield_min")
    if gmin is not None:
        yield_kg_acre = round(float(gmin) * 404.686, 1)

    # Base row using columns guaranteed to exist
    row: dict = {
        "variety_name":       d.get("variety_name", "").strip(),
        "crop_type_en":       crop_en,
        "crop_type_sw":       crop_sw,
        "tosci_certified":    True,
        "source_url":         d.get("detail_url") or d.get("source_url") or "",
    }

    # Existing columns that have better data from scraper
    if "recommended_regions" in existing_cols and regions:
        row["recommended_regions"] = regions
    if "breeder" in existing_cols and d.get("registrant"):
        row["breeder"] = d["registrant"]
    if "yield_kg_per_acre" in existing_cols and yield_kg_acre is not None:
        row["yield_kg_per_acre"] = yield_kg_acre
    if "maturity_days" in existing_cols and d.get("days_to_tasseling"):
        row["maturity_days"] = d["days_to_tasseling"]

    # New columns (only if migration has been applied)
    if "registrant" in existing_cols:
        row["registrant"] = d.get("registrant") or None
    if "registration_year" in existing_cols:
        row["registration_year"] = reg_year
    if "crop_scientific" in existing_cols:
        row["crop_scientific"] = d.get("crop_scientific") or None
    if "crop_full_name" in existing_cols:
        row["crop_full_name"] = d.get("crop_full_name") or d.get("zao") or None
    if "altitude_range" in existing_cols:
        row["altitude_range"] = d.get("altitude_range") or None
    if "altitude_min" in existing_cols:
        row["altitude_min"] = d.get("altitude_min") or None
    if "altitude_max" in existing_cols:
        row["altitude_max"] = d.get("altitude_max") or None
    if "suitable_regions" in existing_cols:
        row["suitable_regions"] = regions or None
    if "grain_yield" in existing_cols:
        row["grain_yield"] = d.get("grain_yield") or None
    if "grain_yield_min" in existing_cols:
        row["grain_yield_min"] = d.get("grain_yield_min") or None
    if "grain_yield_max" in existing_cols:
        row["grain_yield_max"] = d.get("grain_yield_max") or None
    if "distinctive_characters" in existing_cols:
        row["distinctive_characters"] = d.get("distinctive_characters") or None
    if "days_to_tasseling" in existing_cols:
        row["days_to_tasseling"] = d.get("days_to_tasseling") or None
    if "plant_height_cm" in existing_cols:
        row["plant_height_cm"] = d.get("plant_height_cm") or None
    if "grain_size" in existing_cols:
        row["grain_size"] = d.get("grain_size") or None
    if "stem_colour" in existing_cols:
        row["stem_colour"] = d.get("stem_colour") or None
    if "detail_url" in existing_cols:
        row["detail_url"] = d.get("detail_url") or None
    if "additional_fields" in existing_cols:
        row["additional_fields"] = d.get("additional_fields") or None

    return row


def get_existing_columns() -> set[str]:
    """Query Supabase to find out which columns actually exist in seed_varieties."""
    try:
        res = supabase.table("seed_varieties").select("*").limit(1).execute()
        if res.data:
            return set(res.data[0].keys())
    except Exception as e:
        log.warning(f"Could not detect columns: {e}")
    # Fallback: base columns that definitely exist
    return {"variety_name", "crop_type_en", "crop_type_sw", "tosci_certified", "source_url"}


def filter_row(row: dict, allowed_cols: set[str]) -> dict:
    return {k: v for k, v in row.items() if k in allowed_cols}


def _upsert_row(row: dict) -> bool:
    """Update existing row by variety_name, or insert if not found."""
    name = row.get("variety_name", "")
    if not name:
        return False
    try:
        # Try update first
        upd = {k: v for k, v in row.items() if k != "variety_name"}
        res = supabase.table("seed_varieties").update(upd).eq("variety_name", name).execute()
        if res.data:
            return True
        # Not found — insert
        supabase.table("seed_varieties").insert(row).execute()
        return True
    except Exception as e:
        log.warning(f"  ✗ {name}: {str(e)[:80]}")
        return False


def upload(records: list[dict]) -> tuple[int, int]:
    existing_cols = get_existing_columns()
    log.info(f"  Table has {len(existing_cols)} columns: {', '.join(sorted(existing_cols))}")

    # Fetch existing variety names for fast lookup
    try:
        res = supabase.table("seed_varieties").select("variety_name").execute()
        existing_names = {r["variety_name"].strip().lower() for r in res.data if r.get("variety_name")}
        log.info(f"  {len(existing_names)} existing rows in Supabase")
    except Exception as e:
        log.warning(f"Could not fetch existing names: {e}")
        existing_names = set()

    # Check which new columns are missing (need migration)
    all_new = {"registrant","registration_year","crop_scientific","crop_full_name",
               "altitude_range","altitude_min","altitude_max","suitable_regions",
               "grain_yield","grain_yield_min","grain_yield_max",
               "distinctive_characters","days_to_tasseling","plant_height_cm",
               "grain_size","stem_colour","detail_url","additional_fields"}
    missing = all_new - existing_cols
    if missing:
        log.warning(f"  Migration not yet applied — {len(missing)} new columns missing")
        log.warning("  → Run scripts/migrate_seed_varieties_detailed.sql in Supabase SQL Editor")
        log.warning("  → Then re-run this script to populate the new columns")
        log.info("  Uploading to existing columns now (regions, breeder, yield will be populated)...")

    uploaded = failed = 0

    for i, d in enumerate(records):
        name = (d.get("variety_name") or "").strip()
        if not name:
            continue

        row = build_row(d, existing_cols)
        try:
            if name.lower() in existing_names:
                # UPDATE existing row
                upd = {k: v for k, v in row.items() if k != "variety_name"}
                supabase.table("seed_varieties").update(upd).eq("variety_name", name).execute()
            else:
                # INSERT new row
                supabase.table("seed_varieties").insert(row).execute()
                existing_names.add(name.lower())
            uploaded += 1
        except Exception as e:
            failed += 1
            log.warning(f"  ✗ {name}: {str(e)[:80]}")

        if (i + 1) % 50 == 0:
            pct = round((i + 1) / len(records) * 100)
            log.info(f"  Processed {i+1}/{len(records)} ({pct}%) — {uploaded} ok, {failed} failed")

        time.sleep(0.05)  # light throttle

    return uploaded, failed


def main():
    print("\n" + "=" * 60)
    print("  TOSCI DETAILED UPLOAD — Supabase")
    print("=" * 60)

    if not os.path.exists(DETAIL_JSON):
        print(f"\n  ✗ JSON file not found: {DETAIL_JSON}")
        print("     Run scrape_tosci_detailed.py first.")
        return

    with open(DETAIL_JSON, encoding="utf-8") as f:
        details = json.load(f)
    print(f"\n  Loaded {len(details)} varieties from JSON")

    valid = [d for d in details if d.get("variety_name", "").strip()]
    print(f"  Prepared {len(valid)} varieties for upsert")
    print("  Uploading to Supabase (upsert on variety_name)...")

    uploaded, failed = upload(valid)

    # Final count from DB
    try:
        res = supabase.table("seed_varieties").select("id", count="exact").execute()
        total_db = res.count
    except Exception:
        total_db = "?"

    print("\n" + "=" * 60)
    print("  UPLOAD COMPLETE")
    print("=" * 60)
    print(f"  ✓ Rows upserted     : {uploaded}")
    print(f"  ✗ Failed            : {failed}")
    print(f"  📊 Total in Supabase: {total_db}")

    # Crop breakdown
    from collections import Counter
    existing_cols = get_existing_columns()
    counts = Counter(resolve_crop_en(d)[0] for d in valid)
    print("\n  Crop breakdown:")
    for crop, n in counts.most_common(20):
        sw = CROP_SW_LABELS.get(crop, "")
        print(f"    {crop:<24} ({sw:<18}) {n:>4}")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
