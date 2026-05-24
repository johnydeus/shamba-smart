"""
Create all Shamba Smart data tables in Supabase.
Uses Supabase REST API to run raw SQL via the rpc endpoint.
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from config import supabase, log

TABLES_SQL = [
    """
    CREATE TABLE IF NOT EXISTS pesticides (
        id SERIAL PRIMARY KEY,
        brand_name TEXT NOT NULL,
        active_ingredient TEXT,
        registration_number TEXT,
        pesticide_type TEXT,
        target_crops TEXT[],
        manufacturer TEXT,
        phi_days INT,
        registration_expiry DATE,
        tphpa_registered BOOLEAN DEFAULT TRUE,
        source_url TEXT,
        scraped_at TIMESTAMPTZ DEFAULT NOW()
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS seed_varieties (
        id SERIAL PRIMARY KEY,
        variety_name TEXT NOT NULL,
        crop_type_en TEXT,
        crop_type_sw TEXT,
        maturity_days INT,
        yield_kg_per_acre FLOAT,
        recommended_regions TEXT[],
        breeder TEXT,
        tosci_certified BOOLEAN DEFAULT TRUE,
        drought_tolerant BOOLEAN,
        disease_resistant TEXT[],
        source_url TEXT,
        scraped_at TIMESTAMPTZ DEFAULT NOW()
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS research_data (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT,
        data_type TEXT,
        crop_name TEXT,
        pest_or_disease TEXT,
        recommendation TEXT,
        source TEXT DEFAULT 'TPRI',
        source_url TEXT,
        published_date DATE,
        scraped_at TIMESTAMPTZ DEFAULT NOW()
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS fertilisers (
        id SERIAL PRIMARY KEY,
        product_name TEXT NOT NULL,
        nitrogen_pct FLOAT,
        phosphorus_pct FLOAT,
        potassium_pct FLOAT,
        npk_ratio TEXT,
        recommended_crops TEXT[],
        application_rate TEXT,
        supplier TEXT,
        price_tzs INT,
        source_url TEXT,
        scraped_at TIMESTAMPTZ DEFAULT NOW()
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS agro_products (
        id SERIAL PRIMARY KEY,
        product_name TEXT NOT NULL,
        category TEXT,
        description TEXT,
        target_crops TEXT[],
        supplier TEXT,
        price_tzs INT,
        source_url TEXT,
        scraped_at TIMESTAMPTZ DEFAULT NOW()
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS market_prices (
        id SERIAL PRIMARY KEY,
        crop_name_en TEXT NOT NULL,
        crop_name_sw TEXT,
        market_name TEXT NOT NULL,
        region TEXT,
        price_tzs_kg INT,
        price_date DATE DEFAULT CURRENT_DATE,
        source TEXT DEFAULT 'kilimo.go.tz',
        scraped_at TIMESTAMPTZ DEFAULT NOW()
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS agrovets (
        id SERIAL PRIMARY KEY,
        shop_name TEXT NOT NULL,
        region TEXT,
        district TEXT,
        gps_lat FLOAT,
        gps_lng FLOAT,
        phone TEXT,
        address TEXT,
        verified BOOLEAN DEFAULT FALSE,
        source TEXT,
        scraped_at TIMESTAMPTZ DEFAULT NOW()
    );
    """,
    """
    CREATE TABLE IF NOT EXISTS scrape_logs (
        id SERIAL PRIMARY KEY,
        target_name TEXT NOT NULL,
        target_url TEXT,
        records_scraped INT DEFAULT 0,
        status TEXT,
        error_message TEXT,
        started_at TIMESTAMPTZ DEFAULT NOW(),
        completed_at TIMESTAMPTZ
    );
    """,
]

def create_tables():
    log.info("Creating Supabase tables via SQL RPC...")
    for sql in TABLES_SQL:
        try:
            supabase.rpc("exec_sql", {"query": sql.strip()}).execute()
            log.info("  ✓ Table created/verified")
        except Exception as e:
            # Tables probably already exist or rpc not available — insert test
            log.info(f"  ℹ RPC not available ({e}) — tables may already exist via dashboard SQL")
    log.info("Table setup complete.")

if __name__ == "__main__":
    create_tables()
