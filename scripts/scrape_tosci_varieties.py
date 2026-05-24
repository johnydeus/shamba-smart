"""
TOSCI National Seed Varieties Scraper
Scrapes tosci.go.tz/seed-varieties (60 pages, ~1,200 varieties).
Page structure: div.searchable-record with data-name attribute.
Columns: # | AINA (variety) | ZAO (crop scientific name) | Registrant | Year
Uploads to Supabase seed_varieties table and saves CSV backup.
"""
import sys, os, csv, time, re, requests
sys.path.insert(0, os.path.dirname(__file__))
from bs4 import BeautifulSoup
from config import supabase, log, CROP_SW_TO_EN, random_headers

BASE_URL    = "https://www.tosci.go.tz/seed-varieties"
OUTPUT_CSV  = os.path.join(os.path.dirname(__file__), "output", "tosci_varieties_all.csv")
SCREENSHOTS = os.path.join(os.path.dirname(__file__), "screenshots")

# ── Crop normalisation ────────────────────────────────────────────────────────
# Scientific name → common English name
SCIENTIFIC_TO_EN = {
    "zea mays":             "maize",
    "oryza sativa":         "rice",
    "manihot":              "cassava",
    "solanum lycopersicum": "tomato",
    "lycopersicon":         "tomato",
    "phaseolus vulgaris":   "beans",
    "vigna":                "cowpea",
    "cajanus cajan":        "pigeon pea",
    "hordeum vulgare":      "barley",
    "triticum":             "wheat",
    "sorghum bicolor":      "sorghum",
    "helianthus annus":     "sunflower",
    "helianthus annuus":    "sunflower",
    "gossypium":            "cotton",
    "arachis hypogaea":     "groundnut",
    "glycine max":          "soybean",
    "anacardium occidentale": "cashew",
    "coffea":               "coffee",
    "camellia sinensis":    "tea",
    "musa":                 "banana",
    "solanum tuberosum":    "potato",
    "ipomoea batatas":      "sweet potato",
    "allium cepa":          "onion",
    "allium":               "onion",
    "capsicum":             "pepper",
    "brassica oleracea":    "cabbage",
    "brassica":             "kale",
    "daucus carota":        "carrot",
    "mangifera indica":     "mango",
    "ananas comosus":       "pineapple",
    "carica papaya":        "papaya",
    "persea americana":     "avocado",
    "sesamum indicum":      "sesame",
    "nicotiana tabacum":    "tobacco",
    "saccharum officinarum": "sugarcane",
    "pennisetum":           "millet",
    "eleusine coracana":    "finger millet",
    "triticale":            "triticale",
    "citrullus lanatus":    "watermelon",
    "cucumis melo":         "melon",
    "cucumis sativus":      "cucumber",
    "abelmoschus esculentus": "okra",
    "spinacia":             "spinach",
    "beta vulgaris":        "beetroot",
    "lactuca sativa":       "lettuce",
    "cucurbita":            "pumpkin",
    "lupinus":              "lupin",
    "lentil":               "lentil",
    "pisum sativum":        "peas",
    "lens culinaris":       "lentil",
}

CROP_COMMON_TO_EN = {
    **CROP_SW_TO_EN,
    "maize": "maize", "rice": "rice", "paddy": "rice",
    "cassava": "cassava", "tomato": "tomato", "tomatoes": "tomato",
    "beans": "beans", "bean": "beans", "cowpea": "cowpea",
    "pigeon pea": "pigeon pea", "barley": "barley", "wheat": "wheat",
    "triticale": "triticale", "sorghum": "sorghum", "sunflower": "sunflower",
    "cotton": "cotton", "groundnut": "groundnut", "groundnuts": "groundnut",
    "soybean": "soybean", "soybeans": "soybean", "soya": "soybean",
    "cashew": "cashew", "coffee": "coffee", "tea": "tea",
    "banana": "banana", "potato": "potato", "sweet potato": "sweet potato",
    "onion": "onion", "onions": "onion", "pepper": "pepper", "chilli": "pepper",
    "cabbage": "cabbage", "kale": "kale", "carrot": "carrot", "carrots": "carrot",
    "mango": "mango", "pineapple": "pineapple", "papaya": "papaya",
    "avocado": "avocado", "sesame": "sesame", "tobacco": "tobacco",
    "sugarcane": "sugarcane", "millet": "millet", "finger millet": "finger millet",
    "watermelon": "watermelon", "cucumber": "cucumber", "okra": "okra",
    "spinach": "spinach", "lettuce": "lettuce", "pumpkin": "pumpkin",
    "peas": "peas",
}

CROP_SW_LABELS = {
    "maize": "Mahindi", "rice": "Mchele/Mpunga", "cassava": "Muhogo",
    "tomato": "Nyanya", "beans": "Maharagwe", "cowpea": "Choroko",
    "pigeon pea": "Mbaazi", "barley": "Shayiri", "wheat": "Ngano",
    "triticale": "Triticale", "sorghum": "Mtama", "sunflower": "Alizeti",
    "cotton": "Pamba", "groundnut": "Karanga", "soybean": "Soya",
    "cashew": "Korosho", "coffee": "Kahawa", "tea": "Chai",
    "banana": "Ndizi", "potato": "Viazi", "sweet potato": "Viazi Vitamu",
    "onion": "Vitunguu", "pepper": "Pilipili", "cabbage": "Kabichi",
    "kale": "Sukuma Wiki", "carrot": "Karoti", "mango": "Embe",
    "pineapple": "Nanasi", "papaya": "Papai", "avocado": "Parachichi",
    "sesame": "Ufuta", "tobacco": "Tumbaku", "sugarcane": "Miwa",
    "millet": "Uwele", "finger millet": "Ulezi", "watermelon": "Tikiti Maji",
    "cucumber": "Tango", "okra": "Bamia", "spinach": "Mchicha",
    "lettuce": "Saladi", "pumpkin": "Boga", "peas": "Mbaazi Ndogo",
}


def normalise_crop(raw: str) -> tuple[str, str]:
    """Return (en_name, sw_name) from raw ZAO text (may be scientific name)."""
    if not raw:
        return ("other", "Nyingine")
    lower = raw.lower().strip()

    # Try scientific name lookup first (exact partial match)
    for sci, en in SCIENTIFIC_TO_EN.items():
        if sci in lower:
            sw = CROP_SW_LABELS.get(en, en.title())
            return (en, sw)

    # Try common name lookup
    for common, en in CROP_COMMON_TO_EN.items():
        if common in lower:
            sw = CROP_SW_LABELS.get(en, en.title())
            return (en, sw)

    # Extract first meaningful word as fallback
    words = re.sub(r'\(.*?\)', '', lower).strip().split()
    first = words[0] if words else lower
    return (first, raw.strip().split("(")[0].strip().title())


# ── Scraper ───────────────────────────────────────────────────────────────────

def scrape_page(session: requests.Session, page_num: int) -> list[dict]:
    url = BASE_URL if page_num == 1 else f"{BASE_URL}?page={page_num}"
    for attempt in range(3):
        try:
            r = session.get(url, headers=random_headers(), timeout=20)
            if r.status_code != 200:
                log.warning(f"HTTP {r.status_code} on page {page_num}")
                return []
            break
        except Exception as e:
            if attempt == 2:
                log.warning(f"Request failed page {page_num}: {e}")
                return []
            time.sleep(2)

    soup = BeautifulSoup(r.text, "html.parser")
    records = []

    for div in soup.find_all("div", attrs={"data-name": True}):
        variety_name = div["data-name"].strip()
        if not variety_name:
            continue

        # Extract columns from inner divs
        cols = div.find_all("div", recursive=False)
        if not cols:
            # Try the anchor's inner divs
            anchor = div.find("a")
            if anchor:
                cols = anchor.find_all("div", recursive=False)

        crop_raw = ""
        registrant = ""
        year = None

        # Column layout: [#/Name] [Crop] [Registrant] [Year]
        col_texts = []
        for col in cols:
            txt = col.get_text(separator=" ", strip=True)
            col_texts.append(txt)

        # variety name may appear in col_texts[0] along with the row number
        # crop is typically col_texts[1], registrant col_texts[2], year col_texts[3]
        if len(col_texts) >= 2:
            crop_raw = col_texts[1].strip()
        if len(col_texts) >= 3:
            registrant = col_texts[2].strip()
        if len(col_texts) >= 4:
            yr_match = re.search(r'\b(19|20)\d{2}\b', col_texts[3])
            if yr_match:
                year = int(yr_match.group())

        # Clean variety name: remove leading row number if present
        clean_name = re.sub(r'^\s*\d+\s*', '', variety_name).strip()
        if not clean_name:
            clean_name = variety_name.strip()

        en, sw = normalise_crop(crop_raw)
        records.append({
            "variety_name":    clean_name,
            "crop_type_en":    en,
            "crop_type_sw":    sw,
            "tosci_certified": True,
            "source_url":      url,
        })

    return records


def get_total_pages(session: requests.Session) -> int:
    try:
        r = session.get(BASE_URL, headers=random_headers(), timeout=20)
        soup = BeautifulSoup(r.text, "html.parser")
        pager = soup.find("ul", class_="pagination")
        if pager:
            nums = []
            for a in pager.find_all("a", href=True):
                m = re.search(r'page=(\d+)', a["href"])
                if m:
                    nums.append(int(m.group(1)))
            if nums:
                return max(nums)
    except Exception as e:
        log.warning(f"Could not detect total pages: {e}")
    return 59  # known default


def scrape_all() -> list[dict]:
    session = requests.Session()
    total_pages = get_total_pages(session)
    log.info(f"Detected {total_pages} pages to scrape")

    all_records = []
    seen = set()

    for page_num in range(1, total_pages + 1):
        page_records = scrape_page(session, page_num)
        new = 0
        for rec in page_records:
            key = rec["variety_name"].lower()
            if key not in seen:
                seen.add(key)
                all_records.append(rec)
                new += 1

        log.info(f"  Page {page_num:>2}/{total_pages}: {new:>3} varieties (total: {len(all_records)})")

        # Polite delay between requests
        if page_num < total_pages:
            time.sleep(0.8)

    return all_records


# ── CSV backup ────────────────────────────────────────────────────────────────

def save_csv(records: list[dict]):
    os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)
    fields = ["variety_name", "crop_type_en", "crop_type_sw",
              "tosci_certified", "source_url"]
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction="ignore")
        w.writeheader()
        w.writerows(records)
    log.info(f"CSV saved: {OUTPUT_CSV}")


# ── Supabase upload ───────────────────────────────────────────────────────────

def upload(records: list[dict]) -> tuple[int, int, int]:
    try:
        res = supabase.table("seed_varieties").select("variety_name").execute()
        existing = {r["variety_name"].strip().lower() for r in res.data if r.get("variety_name")}
        log.info(f"  {len(existing)} existing records in Supabase")
    except Exception as e:
        log.warning(f"Could not fetch existing: {e}")
        existing = set()

    to_insert = [r for r in records
                 if r.get("variety_name", "").strip().lower() not in existing]
    skipped = len(records) - len(to_insert)
    log.info(f"  {skipped} duplicates skipped, uploading {len(to_insert)}")

    uploaded = failed = 0
    BATCH = 50
    for i in range(0, len(to_insert), BATCH):
        batch = to_insert[i:i + BATCH]
        try:
            supabase.table("seed_varieties").insert(batch).execute()
            uploaded += len(batch)
            log.info(f"  Uploaded {uploaded}/{len(to_insert)}...")
        except Exception as e:
            log.warning(f"Batch failed: {str(e)[:120]}")
            for rec in batch:
                try:
                    supabase.table("seed_varieties").insert(rec).execute()
                    uploaded += 1
                except Exception as e2:
                    failed += 1
                    log.warning(f"  ✗ {rec.get('variety_name','?')}: {str(e2)[:80]}")
        time.sleep(0.3)

    return uploaded, skipped, failed


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("\n" + "=" * 60)
    print("  TOSCI SEED VARIETIES SCRAPER")
    print("  Tanzania Official Seed Register")
    print("  URL: https://www.tosci.go.tz/seed-varieties")
    print("=" * 60)

    os.makedirs(SCREENSHOTS, exist_ok=True)
    os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

    print("\n  Scraping pages...")
    records = scrape_all()

    if not records:
        print("\n  ✗ No records scraped. Check network connection.")
        return

    print(f"\n  ✓ Scraped {len(records)} unique varieties")
    save_csv(records)

    # Crop breakdown
    from collections import Counter
    counts = Counter(r["crop_type_en"] for r in records)
    print("\n  Breakdown by crop:")
    for crop, n in counts.most_common(20):
        sw = next((r["crop_type_sw"] for r in records if r["crop_type_en"] == crop), "")
        print(f"    {crop:<22} ({sw:<18}) {n:>4} varieties")

    print("\n  Uploading to Supabase...")
    uploaded, skipped, failed = upload(records)

    try:
        total_res = supabase.table("seed_varieties").select("id", count="exact").execute()
        total_db = total_res.count
    except Exception:
        total_db = "?"

    print("\n" + "=" * 60)
    print("  COMPLETE")
    print("=" * 60)
    print(f"  ✓ Varieties scraped    : {len(records)}")
    print(f"  ✓ Uploaded to Supabase : {uploaded}")
    print(f"  ⚠ Duplicates skipped   : {skipped}")
    print(f"  ✗ Failed               : {failed}")
    print(f"  📊 Total in Supabase   : {total_db}")
    print(f"  💾 CSV backup          : {OUTPUT_CSV}")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    main()
