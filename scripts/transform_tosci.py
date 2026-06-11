#!/usr/bin/env python3
"""Transform raw TOSCI scrape into the app's seed_varieties schema.

Outputs:
  assets/data/tosci_seed_varieties.json  — bundled in-app offline dataset
  scripts/tosci_seed_varieties.sql       — Supabase migration (table + data)
"""
import json
import re

RAW = "scripts/tosci_varieties_raw.json"
OUT_JSON = "assets/data/tosci_seed_varieties.json"
OUT_SQL = "scripts/tosci_seed_varieties.sql"

# Maps a lowercase keyword found in the raw "Zao" value → (crop_type_en, crop_type_sw)
CROP_MAP = [
    ("sweetcorn", ("maize", "Mahindi")),
    ("maize", ("maize", "Mahindi")),
    ("mahindi", ("maize", "Mahindi")),
    ("paddy", ("rice", "Mchele")),
    ("mpunga", ("rice", "Mchele")),
    ("wheat", ("wheat", "Ngano")),
    ("triticale", ("wheat", "Ngano")),
    ("sorghum", ("sorghum", "Mtama")),
    ("mtama", ("sorghum", "Mtama")),
    ("pearl millet", ("millet", "Uwele")),
    ("finger millet", ("finger millet", "Ulezi")),
    ("barley", ("barley", "Shayiri")),
    ("oats", ("barley", "Shayiri")),
    ("soya", ("soybean", "Soya")),
    ("garden bean", ("beans", "Maharagwe")),
    ("frenchbean", ("beans", "Maharagwe")),
    ("french bean", ("beans", "Maharagwe")),
    ("lablab", ("beans", "Maharagwe")),
    ("maharage", ("beans", "Maharagwe")),
    ("bean", ("beans", "Maharagwe")),
    ("cow pea", ("cowpea", "Kunde")),
    ("cowpea", ("cowpea", "Kunde")),
    ("choroko", ("cowpea", "Choroko")),
    ("green gram", ("cowpea", "Choroko")),
    ("ground nut", ("groundnut", "Karanga")),
    ("groundnut", ("groundnut", "Karanga")),
    ("bambaranut", ("groundnut", "Karanga")),
    ("pigeon pea", ("pigeon pea", "Mbaazi")),
    ("chickpea", ("peas", "Njegere")),
    ("tomato", ("tomato", "Nyanya")),
    ("chinese cabbage", ("cabbage", "Kabichi")),
    ("red cabbage", ("cabbage", "Kabichi")),
    ("cabbage", ("cabbage", "Kabichi")),
    ("pak choi", ("cabbage", "Kabichi")),
    ("kale", ("kale", "Sukuma wiki")),
    ("collard", ("kale", "Sukuma wiki")),
    ("callard", ("kale", "Sukuma wiki")),
    ("rape (", ("kale", "Sukuma wiki")),
    ("ethiopian mustard", ("kale", "Sukuma wiki")),
    ("leek", ("onion", "Vitunguu")),
    ("onion", ("onion", "Vitunguu")),
    ("sweet pepper", ("pepper", "Pilipili hoho")),
    ("hot pepper", ("pepper", "Pilipili")),
    ("chill", ("pepper", "Pilipili")),
    ("pepper (piper", ("pepper", "Pilipili manga")),
    ("pepper", ("pepper", "Pilipili hoho")),
    ("carrot", ("carrot", "Karoti")),
    ("okra", ("okra", "Bamia")),
    ("cucumber", ("cucumber", "Tango")),
    ("amaranth", ("spinach", "Mchicha")),
    ("nightshade", ("spinach", "Mnavu")),
    ("swiss chard", ("spinach", "Mchicha")),
    ("spinach", ("spinach", "Mchicha")),
    ("watermelon", ("watermelon", "Tikiti maji")),
    ("melon", ("watermelon", "Tikiti maji")),
    ("squash", ("pumpkin", "Maboga")),
    ("pumpkin", ("pumpkin", "Maboga")),
    ("butternut", ("pumpkin", "Maboga")),
    ("buttenut", ("pumpkin", "Maboga")),
    ("cassava", ("cassava", "Muhogo")),
    ("sweet potato", ("sweet potato", "Viazi vitamu")),
    ("round potato", ("potato", "Viazi")),
    ("potato", ("potato", "Viazi")),
    ("banana", ("banana", "Ndizi")),
    ("papaya", ("papaya", "Papai")),
    ("papai", ("papaya", "Papai")),
    ("grape", ("grape", "Zabibu")),
    ("cotton", ("cotton", "Pamba")),
    ("sunflower", ("sunflower", "Alizeti")),
    ("coffee", ("coffee", "Kahawa")),
    ("tea (", ("tea", "Chai")),
    ("cashew", ("cashew", "Korosho")),
    ("sugar cane", ("sugarcane", "Miwa")),
    ("tobacco", ("tobacco", "Tumbaku")),
    ("sisal", ("sisal", "Katani")),
    ("sesame", ("sesame", "Ufuta")),
    ("eggplant", ("eggplant", "Bilinganya")),
    ("egg plant", ("eggplant", "Bilinganya")),
    ("eubergine", ("eggplant", "Bilinganya")),
    ("broccoli", ("broccoli", "Brokoli")),
    ("cauliflower", ("cauliflower", "Koliflawa")),
    ("letuce", ("lettuce", "Saladi")),
    ("lettuce", ("lettuce", "Saladi")),
    ("beet", ("beetroot", "Bitiruti")),
    ("radish", ("radish", "Figili")),
    ("turnip", ("radish", "Figili")),
    ("wild rocket", ("lettuce", "Saladi")),
    ("celery", ("celery", "Selari")),
    ("coriander", ("coriander", "Giligilani")),
    ("persley", ("coriander", "Giligilani")),
    ("finnel", ("coriander", "Giligilani")),
    ("lucerne", ("fodder", "Malisho")),
    ("desmodium", ("fodder", "Malisho")),
    ("siratro", ("fodder", "Malisho")),
    ("buffel grass", ("fodder", "Malisho")),
    ("boma rhodes", ("fodder", "Malisho")),
    ("ornamental", ("flower", "Maua")),
    ("callery", ("flower", "Maua")),
]

SCI_RE = re.compile(r"[\(\[]\s*(.*?)\s*[\)\]]")
YEAR_RE = re.compile(r"(\d{4})")
NUM_RE = re.compile(r"(\d+(?:\.\d+)?)")
MATURITY_MONTHS_RE = re.compile(r"maturity[:\s]*([\d.]+)\s*(?:-|to|–)?\s*([\d.]+)?\s*month", re.I)
MATURITY_DAYS_RE = re.compile(r"maturity[:\s]*([\d.]+)\s*(?:-|to|–)?\s*([\d.]+)?\s*day", re.I)
RESIST_RE = re.compile(
    r"(?:resistan(?:t|ce)|toleran(?:t|ce))\s+to\s+([^.;]+)", re.I)


def norm_crop(zao):
    z = (zao or "").lower()
    for key, val in CROP_MAP:
        if key in z:
            return val
    return ("other", "Nyingine")


def parse_regions(raw):
    if not raw:
        return []
    txt = raw.strip().rstrip(".")
    # Long prose (e.g. "All maize growing areas of Tanzania") stays whole
    if len(txt) > 90 and "," not in txt:
        return [txt]
    parts = re.split(r",| and | na | & ", txt)
    return [p.strip().title() for p in parts if p.strip()]


def parse_year(raw):
    m = YEAR_RE.search(raw or "")
    return int(m.group(1)) if m else None


def parse_yield_min(raw):
    m = NUM_RE.search(raw or "")
    if not m:
        return None
    v = float(m.group(1))
    # Values in t/ha are small; anything >100 is probably kg-based — convert
    return round(v / 1000, 2) if v > 100 else v


def parse_maturity_days(distinct):
    if not distinct:
        return None
    m = MATURITY_DAYS_RE.search(distinct)
    if m:
        lo = float(m.group(1))
        hi = float(m.group(2)) if m.group(2) else lo
        return int((lo + hi) / 2)
    m = MATURITY_MONTHS_RE.search(distinct)
    if m:
        lo = float(m.group(1))
        hi = float(m.group(2)) if m.group(2) else lo
        return int((lo + hi) / 2 * 30)
    return None


def parse_resistances(special):
    if not special:
        return []
    out = []
    for m in RESIST_RE.finditer(special):
        target = m.group(1).strip()
        # Trim trailing conjunction clauses ("but susceptible to ...")
        target = re.split(r"\bbut\b|\bwhile\b", target, flags=re.I)[0].strip()
        target = target.rstrip(",").strip()
        if target and len(target) < 120:
            out.append(target)
    return out


def is_drought_tolerant(special):
    if not special:
        return None
    s = special.lower()
    if "drought" in s:
        if re.search(r"(susceptible|sensitive)\s+to\s+drought", s):
            return False
        return True
    return None


def main():
    raw = json.load(open(RAW))
    rows = []
    seen = set()
    for r in raw:
        name = (r.get("Jina") or "").strip()
        if not name:
            continue
        key = name.lower()
        if key in seen:
            key = key + "::" + r["detail_url"]
        seen.add(key)

        zao = r.get("Zao", "")
        crop_en, crop_sw = norm_crop(zao)
        sci = None
        m = SCI_RE.search(zao or "")
        if m:
            sci = m.group(1).strip()

        distinct = r.get("Distinctive Characters") or None
        special = r.get("Special Attributes") or None

        rows.append({
            "variety_name": name,
            "crop_type_en": crop_en,
            "crop_type_sw": crop_sw,
            "crop_scientific": sci,
            "crop_raw": zao or None,
            "registration_year": parse_year(r.get("Mwaka wa Usajili")),
            "registrant": r.get("Registrant / Applicant") or None,
            "altitude_range": r.get("Production Altitude and Range") or None,
            "suitable_regions": parse_regions(r.get("Maeneo Yanayo Faa")),
            "grain_yield": r.get("Grain Yield") or None,
            "grain_yield_min": parse_yield_min(r.get("Grain Yield")),
            "distinctive_characters": distinct,
            "special_attributes": special,
            "maturity_days": parse_maturity_days(distinct),
            "drought_tolerant": is_drought_tolerant(special),
            "disease_resistant": parse_resistances(special),
            "tosci_certified": True,
            "detail_url": r["detail_url"],
            "source_url": "https://www.tosci.go.tz/seed-varieties",
        })

    rows.sort(key=lambda x: (x["crop_type_en"], x["variety_name"].lower()))

    with open(OUT_JSON, "w") as f:
        json.dump(rows, f, ensure_ascii=False, separators=(",", ":"))
    print(f"Wrote {len(rows)} rows to {OUT_JSON}")

    # ── SQL migration ────────────────────────────────────────────────────────
    def sql_str(v):
        if v is None:
            return "NULL"
        return "'" + str(v).replace("'", "''") + "'"

    def sql_arr(v):
        if not v:
            return "NULL"
        inner = ",".join(sql_str(x) for x in v)
        return f"ARRAY[{inner}]::text[]"

    def sql_val(v):
        if v is None:
            return "NULL"
        if isinstance(v, bool):
            return "TRUE" if v else "FALSE"
        if isinstance(v, (int, float)):
            return str(v)
        return sql_str(v)

    cols = ["variety_name", "crop_type_en", "crop_type_sw", "crop_scientific",
            "registration_year", "registrant", "altitude_range",
            "suitable_regions", "grain_yield", "grain_yield_min",
            "distinctive_characters", "special_attributes", "maturity_days",
            "drought_tolerant", "disease_resistant", "tosci_certified",
            "detail_url", "source_url"]

    with open(OUT_SQL, "w") as f:
        f.write("""-- TOSCI seed varieties: full registry scraped from
-- https://www.tosci.go.tz/seed-varieties (%d varieties)
-- Run this in the Supabase SQL editor.

CREATE TABLE IF NOT EXISTS seed_varieties (
  id BIGSERIAL PRIMARY KEY,
  variety_name TEXT NOT NULL,
  crop_type_en TEXT,
  crop_type_sw TEXT,
  crop_scientific TEXT,
  registration_year INT,
  registrant TEXT,
  altitude_range TEXT,
  suitable_regions TEXT[],
  grain_yield TEXT,
  grain_yield_min NUMERIC,
  distinctive_characters TEXT,
  special_attributes TEXT,
  maturity_days INT,
  drought_tolerant BOOLEAN,
  disease_resistant TEXT[],
  tosci_certified BOOLEAN DEFAULT TRUE,
  detail_url TEXT UNIQUE,
  source_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add columns in case an older version of the table exists
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS crop_scientific TEXT;
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS registration_year INT;
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS registrant TEXT;
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS altitude_range TEXT;
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS suitable_regions TEXT[];
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS grain_yield TEXT;
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS grain_yield_min NUMERIC;
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS distinctive_characters TEXT;
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS special_attributes TEXT;
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS maturity_days INT;
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS drought_tolerant BOOLEAN;
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS disease_resistant TEXT[];
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS tosci_certified BOOLEAN DEFAULT TRUE;
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS detail_url TEXT;
ALTER TABLE seed_varieties ADD COLUMN IF NOT EXISTS source_url TEXT;

-- Allow public read access
ALTER TABLE seed_varieties ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "seed_varieties_public_read" ON seed_varieties;
CREATE POLICY "seed_varieties_public_read" ON seed_varieties
  FOR SELECT USING (TRUE);

-- Replace existing data with the freshly scraped registry
TRUNCATE seed_varieties;

""" % len(rows))
        f.write(f"INSERT INTO seed_varieties ({', '.join(cols)}) VALUES\n")
        chunks = []
        for row in rows:
            vals = []
            for c in cols:
                v = row[c]
                vals.append(sql_arr(v) if c in ("suitable_regions", "disease_resistant") else sql_val(v))
            chunks.append("(" + ", ".join(vals) + ")")
        f.write(",\n".join(chunks))
        f.write(";\n")
    print(f"Wrote SQL migration to {OUT_SQL}")

    # Coverage summary
    n = len(rows)
    for c in ["altitude_range", "suitable_regions", "grain_yield",
              "distinctive_characters", "special_attributes",
              "maturity_days", "registration_year"]:
        filled = sum(1 for r in rows if r[c])
        print(f"  {c}: {filled}/{n}")


if __name__ == "__main__":
    main()
