"""
TOSCI Detailed Scraper — Shamba Smart
Phase 1: Scrape all 60 list pages (variety name + detail URL)
Phase 2: Scrape every detail page for full agronomic data
Output: CSV, JSON, Excel files in scripts/output/

Detail page HTML structure (confirmed):
  labels → div.faded.text-capitalize
  values → div.text-dark.mt-0
"""
from __future__ import annotations
import sys, os, re, csv, json, time, requests
sys.path.insert(0, os.path.dirname(__file__))
import pandas as pd
from bs4 import BeautifulSoup
from config import supabase, log, random_headers

BASE_URL   = "https://www.tosci.go.tz"
OUT_DIR    = os.path.join(os.path.dirname(__file__), "output")
SS_DIR     = os.path.join(os.path.dirname(__file__), "screenshots")
LIST_CSV   = os.path.join(OUT_DIR, "tosci_list.csv")
DETAIL_CSV = os.path.join(OUT_DIR, "tosci_varieties_detailed.csv")
DETAIL_JSON= os.path.join(OUT_DIR, "tosci_varieties_detailed.json")
DETAIL_XLS = os.path.join(OUT_DIR, "tosci_varieties_detailed.xlsx")
PROGRESS_DIR = os.path.join(OUT_DIR, "progress")


# ── Utility ───────────────────────────────────────────────────────────────────

def _get(url: str, retries=3) -> requests.Response | None:
    for attempt in range(retries):
        try:
            r = requests.get(url, headers=random_headers(), timeout=20, verify=False)
            if r.status_code == 200:
                return r
            log.warning(f"HTTP {r.status_code}: {url}")
        except Exception as e:
            if attempt == retries - 1:
                log.warning(f"Failed {url}: {e}")
            time.sleep(1.5)
    return None


def _soup(r: requests.Response) -> BeautifulSoup:
    return BeautifulSoup(r.text, "html.parser")


# ── Phase 1: List pages ───────────────────────────────────────────────────────

def scrape_list_page(page_num: int) -> list[dict]:
    url = BASE_URL + "/seed-varieties" + (f"?page={page_num}" if page_num > 1 else "")
    r = _get(url)
    if not r:
        return []
    soup = _soup(r)
    records = []
    for div in soup.find_all("div", attrs={"data-name": True}):
        variety_name = div["data-name"].strip()
        if not variety_name:
            continue
        # Clean leading row number from data-name (e.g. " H 515")
        clean_name = re.sub(r'^\s*\d+\s*', '', variety_name).strip()

        # Extract detail page URL from the anchor inside the record
        anchor = div.find("a", href=True)
        detail_url = anchor["href"] if anchor else ""
        if detail_url and not detail_url.startswith("http"):
            detail_url = BASE_URL + detail_url

        # Extract the 4 columns: # | AINA | ZAO | Registrant | Year
        cols = anchor.find_all("div", recursive=False) if anchor else []
        col_texts = [c.get_text(separator=" ", strip=True) for c in cols]

        # Col 0: "1  H 515"  →  strip the number
        aina = re.sub(r'^\d+\s*', '', col_texts[0]).strip() if col_texts else clean_name
        zao  = col_texts[1].strip() if len(col_texts) > 1 else ""
        reg  = col_texts[2].strip() if len(col_texts) > 2 else ""
        year_raw = col_texts[3].strip() if len(col_texts) > 3 else ""
        yr_match = re.search(r'\b(19|20)\d{2}\b', year_raw)
        year = int(yr_match.group()) if yr_match else None

        records.append({
            "variety_name": aina or clean_name,
            "crop_full":    zao,
            "registrant":   reg,
            "year":         year,
            "detail_url":   detail_url,
        })
    return records


def phase1_scrape_list() -> list[dict]:
    print("=" * 55)
    print("  PHASE 1 — Scraping variety list (all pages)")
    print("=" * 55)

    # Detect total pages
    r = _get(BASE_URL + "/seed-varieties")
    total_pages = 60
    if r:
        soup = _soup(r)
        pager = soup.find("ul", class_="pagination")
        if pager:
            nums = [int(m.group(1)) for a in pager.find_all("a", href=True)
                    if (m := re.search(r'page=(\d+)', a["href"]))]
            if nums:
                total_pages = max(nums)
    log.info(f"Total list pages: {total_pages}")

    all_varieties = []
    seen_names = set()

    for page_num in range(1, total_pages + 1):
        recs = scrape_list_page(page_num)
        new = 0
        for rec in recs:
            key = rec["variety_name"].lower()
            if key not in seen_names:
                seen_names.add(key)
                all_varieties.append(rec)
                new += 1
        log.info(f"  Page {page_num:>2}/{total_pages}: {new:>3} varieties (total: {len(all_varieties)})")
        time.sleep(0.5)

    os.makedirs(OUT_DIR, exist_ok=True)
    with open(LIST_CSV, "w", newline="", encoding="utf-8-sig") as f:
        w = csv.DictWriter(f, fieldnames=["variety_name","crop_full","registrant","year","detail_url"])
        w.writeheader()
        w.writerows(all_varieties)

    print(f"\n  ✓ {len(all_varieties)} varieties found — saved to {LIST_CSV}")
    return all_varieties


# ── Phase 2: Detail pages ─────────────────────────────────────────────────────

_LABEL_MAP = {
    "jina":                            "jina",
    "zao":                             "zao",
    "mwaka wa usajili":                "mwaka_usajili",
    "registrant / applicant":          "registrant",
    "registrant/applicant":            "registrant",
    "registrant":                      "registrant",
    "production altitude and range":   "altitude_range",
    "maeneo yanayo faa":               "suitable_regions",
    "grain yield":                     "grain_yield",
    "distinctive characters":          "distinctive_characters",
}


def _parse_detail_html(html: str, variety_name: str, detail_url: str) -> dict:
    soup = BeautifulSoup(html, "html.parser")

    detail = {
        "variety_name":          variety_name,
        "detail_url":            detail_url,
        "jina":                  None,
        "zao":                   None,
        "crop_common":           None,
        "crop_scientific":       None,
        "crop_full_name":        None,
        "mwaka_usajili":         None,
        "registrant":            None,
        "altitude_range":        None,
        "altitude_min":          None,
        "altitude_max":          None,
        "suitable_regions":      [],
        "grain_yield":           None,
        "grain_yield_min":       None,
        "grain_yield_max":       None,
        "distinctive_characters": None,
        "days_to_tasseling":     None,
        "plant_height_cm":       None,
        "grain_size":            None,
        "stem_colour":           None,
        "additional_fields":     {},
    }

    # Primary method: div.faded (label) + div.text-dark (value) pairs
    labels = soup.find_all("div", class_="faded")
    values = soup.find_all("div", class_="text-dark")

    label_texts = [l.get_text(strip=True) for l in labels]
    value_texts = [v.get_text(strip=True) for v in values]

    # Align: skip empty labels
    vi = 0
    for label in label_texts:
        if not label:
            continue
        value = value_texts[vi].strip() if vi < len(value_texts) else ""
        vi += 1

        key = _LABEL_MAP.get(label.lower())
        if key:
            detail[key] = value
        else:
            detail["additional_fields"][label] = value

    # ── Post-process fields ───────────────────────────────────────────────────

    # Zao → crop_common + crop_scientific
    if detail["zao"]:
        zao = detail["zao"]
        m = re.match(r'^(.*?)\s*\(([^)]+)\)', zao)
        if m:
            detail["crop_common"]     = m.group(1).strip()
            detail["crop_scientific"] = m.group(2).strip()
            detail["crop_full_name"]  = zao
        else:
            detail["crop_common"]     = zao
            detail["crop_full_name"]  = zao

    # Altitude: "1200-1600" → min:1200, max:1600
    if detail["altitude_range"]:
        m = re.search(r'(\d+)\s*[-–]\s*(\d+)', detail["altitude_range"])
        if m:
            detail["altitude_min"] = int(m.group(1))
            detail["altitude_max"] = int(m.group(2))
        else:
            m2 = re.search(r'(\d+)', detail["altitude_range"])
            if m2:
                detail["altitude_min"] = int(m2.group(1))

    # Suitable regions: comma-separated → list
    if detail["suitable_regions"] and isinstance(detail["suitable_regions"], str):
        detail["suitable_regions"] = [
            r.strip() for r in detail["suitable_regions"].split(",")
            if r.strip()
        ]

    # Grain yield: "4.0-5.0" → min/max floats
    if detail["grain_yield"]:
        m = re.search(r'([\d.]+)\s*[-–]\s*([\d.]+)', detail["grain_yield"])
        if m:
            detail["grain_yield_min"] = float(m.group(1))
            detail["grain_yield_max"] = float(m.group(2))
        else:
            m2 = re.search(r'([\d.]+)', detail["grain_yield"])
            if m2:
                detail["grain_yield_min"] = float(m2.group(1))

    # Distinctive characters → parse sub-fields
    if detail["distinctive_characters"]:
        dc = detail["distinctive_characters"]
        # Days to tasseling
        m = re.search(r'Days to 50\s*%\s*tasseling[:\s]*(\d+)', dc, re.I)
        if m:
            detail["days_to_tasseling"] = int(m.group(1))
        # Plant height
        m = re.search(r'Plant height[:\s]*([\d]+)\s*cm', dc, re.I)
        if m:
            detail["plant_height_cm"] = int(m.group(1))
        # Grain size
        m = re.search(r'Grain size[:\s]*([^,\n]+)', dc, re.I)
        if m:
            detail["grain_size"] = m.group(1).strip()
        # Stem colour
        m = re.search(r'Stem colou?r[:\s]*([^,\n]+)', dc, re.I)
        if m:
            detail["stem_colour"] = m.group(1).strip()

    return detail


def scrape_detail(variety_name: str, detail_url: str) -> dict:
    detail = {
        "variety_name": variety_name, "detail_url": detail_url,
        "jina": None, "zao": None, "crop_common": None,
        "crop_scientific": None, "crop_full_name": None,
        "mwaka_usajili": None, "registrant": None,
        "altitude_range": None, "altitude_min": None, "altitude_max": None,
        "suitable_regions": [], "grain_yield": None,
        "grain_yield_min": None, "grain_yield_max": None,
        "distinctive_characters": None, "days_to_tasseling": None,
        "plant_height_cm": None, "grain_size": None, "stem_colour": None,
        "additional_fields": {},
    }
    if not detail_url:
        return detail
    r = _get(detail_url)
    if not r:
        return detail
    return _parse_detail_html(r.text, variety_name, detail_url)


def phase2_scrape_details(varieties: list[dict]) -> list[dict]:
    print("\n" + "=" * 55)
    print("  PHASE 2 — Scraping variety detail pages")
    print("=" * 55)

    os.makedirs(PROGRESS_DIR, exist_ok=True)
    all_details = []
    total = len(varieties)

    for i, v in enumerate(varieties):
        name = v["variety_name"]
        url  = v.get("detail_url", "")

        detail = scrape_detail(name, url)

        # Merge list-page data as fallback for missing fields
        if not detail["registrant"]:
            detail["registrant"] = v.get("registrant")
        if not detail["mwaka_usajili"]:
            yr = v.get("year")
            detail["mwaka_usajili"] = str(yr) if yr else None
        if not detail["zao"] and v.get("crop_full"):
            detail["zao"] = v["crop_full"]
            if not detail["crop_common"]:
                m = re.match(r'^(.*?)\s*\(', v["crop_full"])
                detail["crop_common"] = m.group(1).strip() if m else v["crop_full"]

        all_details.append(detail)

        # Progress log
        regions = detail.get("suitable_regions") or []
        status = f"{detail['crop_common'] or '?'} | {','.join(regions[:2]) or '—'} | yield:{detail['grain_yield'] or '—'}"
        print(f"  [{i+1:>4}/{total}] {name:<30} {status}")

        # Save progress every 50 varieties
        if (i + 1) % 50 == 0:
            prog_path = os.path.join(PROGRESS_DIR, f"progress_{i+1}.json")
            with open(prog_path, "w", encoding="utf-8") as f:
                json.dump(all_details, f, ensure_ascii=False, indent=2)
            log.info(f"  Progress saved: {i+1} varieties → {prog_path}")

        time.sleep(0.4)  # polite delay

    return all_details


# ── Save outputs ──────────────────────────────────────────────────────────────

def save_results(details: list[dict]):
    os.makedirs(OUT_DIR, exist_ok=True)

    # Flatten for DataFrame (convert lists to strings for CSV/Excel)
    flat = []
    for d in details:
        row = dict(d)
        row["suitable_regions"] = ", ".join(d.get("suitable_regions") or [])
        row["additional_fields"] = json.dumps(d.get("additional_fields") or {})
        flat.append(row)

    df = pd.DataFrame(flat)

    # CSV
    df.to_csv(DETAIL_CSV, index=False, encoding="utf-8-sig")
    log.info(f"CSV saved: {DETAIL_CSV}")

    # JSON (with lists intact)
    with open(DETAIL_JSON, "w", encoding="utf-8") as f:
        json.dump(details, f, ensure_ascii=False, indent=2)
    log.info(f"JSON saved: {DETAIL_JSON}")

    # Excel — one sheet per crop + summary + regions
    try:
        with pd.ExcelWriter(DETAIL_XLS, engine="openpyxl") as writer:
            df.to_excel(writer, index=False, sheet_name="All Varieties")

            # Per-crop sheets
            for crop in sorted(df["crop_common"].dropna().unique()):
                crop_df = df[df["crop_common"] == crop]
                sheet_name = str(crop).replace("/", "-")[:31]
                crop_df.to_excel(writer, index=False, sheet_name=sheet_name)

            # Regions breakdown
            region_rows = []
            for d in details:
                for region in (d.get("suitable_regions") or []):
                    region_rows.append({
                        "variety": d["variety_name"],
                        "crop":    d.get("crop_common"),
                        "region":  region.strip(),
                        "yield":   d.get("grain_yield"),
                        "altitude":d.get("altitude_range"),
                    })
            if region_rows:
                pd.DataFrame(region_rows).to_excel(writer, index=False, sheet_name="By Region")

        log.info(f"Excel saved: {DETAIL_XLS}")
    except Exception as e:
        log.warning(f"Excel save failed: {e}")

    # ── Summary ───────────────────────────────────────────────────────────────
    from collections import Counter

    print("\n" + "=" * 55)
    print("  SCRAPING COMPLETE — SUMMARY")
    print("=" * 55)
    print(f"  Total varieties scraped  : {len(details)}")
    has_regions  = sum(1 for d in details if d.get("suitable_regions"))
    has_yield    = sum(1 for d in details if d.get("grain_yield"))
    has_altitude = sum(1 for d in details if d.get("altitude_range"))
    has_desc     = sum(1 for d in details if d.get("distinctive_characters"))
    print(f"  With regions data        : {has_regions}")
    print(f"  With yield data          : {has_yield}")
    print(f"  With altitude data       : {has_altitude}")
    print(f"  With full description    : {has_desc}")

    print("\n  Breakdown by crop:")
    crop_counts = Counter(d.get("crop_common") or "Unknown" for d in details)
    for crop, n in crop_counts.most_common(20):
        print(f"    {crop:<28} {n:>4} varieties")

    all_regions = [r for d in details for r in (d.get("suitable_regions") or [])]
    if all_regions:
        print("\n  Top suitable regions:")
        for region, n in Counter(all_regions).most_common(15):
            print(f"    {region:<22} {n:>4} varieties")

    print(f"\n  Files saved:")
    print(f"    {DETAIL_CSV}")
    print(f"    {DETAIL_JSON}")
    print(f"    {DETAIL_XLS}")
    print("=" * 55)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    print("\n" + "=" * 55)
    print("  TOSCI DETAILED SCRAPER — SHAMBA SMART")
    print("  Website: https://tosci.go.tz/seed-varieties")
    print("=" * 55)

    import urllib3
    urllib3.disable_warnings()

    # Phase 1 — variety list (reuse existing if already scraped this session)
    if os.path.exists(LIST_CSV):
        print(f"\n  Reusing existing list: {LIST_CSV}")
        with open(LIST_CSV, newline="", encoding="utf-8-sig") as f:
            varieties = list(csv.DictReader(f))
        print(f"  Loaded {len(varieties)} varieties from cache")
    else:
        varieties = phase1_scrape_list()

    if not varieties:
        print("  ✗ No varieties found in Phase 1")
        return

    # Phase 2 — detail pages
    details = phase2_scrape_details(varieties)

    if not details:
        print("  ✗ No details scraped")
        return

    save_results(details)


if __name__ == "__main__":
    main()
