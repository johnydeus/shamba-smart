"""
Master pipeline — runs all scrapers in sequence, logs results, schedules weekly.
"""
import sys, os, time, schedule
from datetime import datetime
sys.path.insert(0, os.path.dirname(__file__))

from scrape_tphpa          import TPHPAScraper
from scrape_tosci          import TOSCIScraper
from scrape_tpri           import TPRIScraper
from scrape_companies      import CompaniesScraper
from scrape_market_prices  import MarketPriceScraper
from scrape_agrovets       import AgrovetScraper
from scraping_report       import run_report
from config                import log

def run_all():
    start = datetime.now()
    log.info("="*55)
    log.info("  SHAMBA SMART DATA PIPELINE STARTING")
    log.info(f"  {start.strftime('%Y-%m-%d %H:%M:%S')}")
    log.info("="*55)

    scrapers = [
        TPHPAScraper(),
        TOSCIScraper(),
        TPRIScraper(),
        CompaniesScraper(),
        MarketPriceScraper(),
        AgrovetScraper(),
    ]

    results = {}
    for scraper in scrapers:
        t0 = time.time()
        scraper.run()
        elapsed = round(time.time() - t0, 1)
        results[scraper.name] = {
            "records": scraper.records_scraped,
            "seconds": elapsed,
        }

    end = datetime.now()
    elapsed_total = (end - start).seconds

    print("\n" + "="*55)
    print("  SHAMBA SMART DATA PIPELINE — COMPLETE")
    print("="*55)
    total = 0
    for name, r in results.items():
        print(f"  ✓ {name:<35} {r['records']:>4} records  ({r['seconds']}s)")
        total += r["records"]
    print("-"*55)
    print(f"  Total records inserted: {total}")
    print(f"  Total time: {elapsed_total}s")
    print(f"  Weekly auto-update: Every Sunday 02:00 AM")
    import schedule as sc
    jobs = sc.get_jobs()
    print(f"  Scheduler active: {len(jobs)} job(s) registered")
    print("="*55)
    print("  All data is now available in your Supabase")
    print("  database and ready for Shamba Smart app use.")
    print("="*55 + "\n")

    run_report()

# Schedule weekly Sunday 02:00
schedule.every().sunday.at("02:00").do(run_all)

if __name__ == "__main__":
    log.info("Running pipeline now...")
    run_all()

    log.info("Pipeline complete. Scheduler running — press Ctrl+C to stop.")
    log.info("Next run: Every Sunday at 02:00 AM")
    # Keep alive for scheduler (only if you want the process to keep running)
    # while True:
    #     schedule.run_pending()
    #     time.sleep(60)
