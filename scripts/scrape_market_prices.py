"""
Tanzania Market Prices Scraper — tries kilimo.go.tz and EAGC, falls back to seed data.
"""
import sys, os, requests, re
from datetime import date
sys.path.insert(0, os.path.dirname(__file__))
from config import supabase, log, random_headers
from scraper_base import BaseScraper

TODAY = date.today().isoformat()

SEED_PRICES = [
    # MAHINDI / MAIZE
    {"crop_name_en":"maize","crop_name_sw":"Mahindi","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":480,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"maize","crop_name_sw":"Mahindi","market_name":"Arusha Central Market","region":"Arusha","price_tzs_kg":420,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"maize","crop_name_sw":"Mahindi","market_name":"Mbeya Market","region":"Mbeya","price_tzs_kg":380,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"maize","crop_name_sw":"Mahindi","market_name":"Dodoma Central Market","region":"Dodoma","price_tzs_kg":390,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"maize","crop_name_sw":"Mahindi","market_name":"Mwanza Market","region":"Mwanza","price_tzs_kg":460,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"maize","crop_name_sw":"Mahindi","market_name":"Morogoro Market","region":"Morogoro","price_tzs_kg":410,"price_date":TODAY,"source":"seed_data"},
    # NYANYA / TOMATO
    {"crop_name_en":"tomato","crop_name_sw":"Nyanya","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":1200,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"tomato","crop_name_sw":"Nyanya","market_name":"Arusha Central Market","region":"Arusha","price_tzs_kg":900,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"tomato","crop_name_sw":"Nyanya","market_name":"Mbeya Market","region":"Mbeya","price_tzs_kg":800,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"tomato","crop_name_sw":"Nyanya","market_name":"Mwanza Market","region":"Mwanza","price_tzs_kg":1100,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"tomato","crop_name_sw":"Nyanya","market_name":"Dodoma Central Market","region":"Dodoma","price_tzs_kg":950,"price_date":TODAY,"source":"seed_data"},
    # MAHARAGWE / BEANS
    {"crop_name_en":"beans","crop_name_sw":"Maharagwe","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":2200,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"beans","crop_name_sw":"Maharagwe","market_name":"Arusha Central Market","region":"Arusha","price_tzs_kg":1900,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"beans","crop_name_sw":"Maharagwe","market_name":"Mbeya Market","region":"Mbeya","price_tzs_kg":1700,"price_date":TODAY,"source":"seed_data"},
    # MCHELE / RICE
    {"crop_name_en":"rice","crop_name_sw":"Mchele","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":1800,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"rice","crop_name_sw":"Mchele","market_name":"Morogoro Market","region":"Morogoro","price_tzs_kg":1650,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"rice","crop_name_sw":"Mchele","market_name":"Mwanza Market","region":"Mwanza","price_tzs_kg":1750,"price_date":TODAY,"source":"seed_data"},
    # VITUNGUU / ONION
    {"crop_name_en":"onion","crop_name_sw":"Vitunguu","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":1800,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"onion","crop_name_sw":"Vitunguu","market_name":"Arusha Central Market","region":"Arusha","price_tzs_kg":1600,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"onion","crop_name_sw":"Vitunguu","market_name":"Dodoma Central Market","region":"Dodoma","price_tzs_kg":1500,"price_date":TODAY,"source":"seed_data"},
    # KAROTI / CARROT
    {"crop_name_en":"carrot","crop_name_sw":"Karoti","market_name":"Arusha Central Market","region":"Arusha","price_tzs_kg":1200,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"carrot","crop_name_sw":"Karoti","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":1400,"price_date":TODAY,"source":"seed_data"},
    # NDIZI / BANANA
    {"crop_name_en":"banana","crop_name_sw":"Ndizi","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":600,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"banana","crop_name_sw":"Ndizi","market_name":"Arusha Central Market","region":"Arusha","price_tzs_kg":500,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"banana","crop_name_sw":"Ndizi","market_name":"Mbeya Market","region":"Mbeya","price_tzs_kg":450,"price_date":TODAY,"source":"seed_data"},
    # MUHOGO / CASSAVA
    {"crop_name_en":"cassava","crop_name_sw":"Muhogo","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":350,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"cassava","crop_name_sw":"Muhogo","market_name":"Dodoma Central Market","region":"Dodoma","price_tzs_kg":320,"price_date":TODAY,"source":"seed_data"},
    # PAMBA / COTTON
    {"crop_name_en":"cotton","crop_name_sw":"Pamba","market_name":"Mwanza Market","region":"Mwanza","price_tzs_kg":1150,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"cotton","crop_name_sw":"Pamba","market_name":"Shinyanga Market","region":"Shinyanga","price_tzs_kg":1100,"price_date":TODAY,"source":"seed_data"},
    # ALIZETI / SUNFLOWER
    {"crop_name_en":"sunflower","crop_name_sw":"Alizeti","market_name":"Dodoma Central Market","region":"Dodoma","price_tzs_kg":1400,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"sunflower","crop_name_sw":"Alizeti","market_name":"Mbeya Market","region":"Mbeya","price_tzs_kg":1300,"price_date":TODAY,"source":"seed_data"},
    # VIAZI VITAMU / SWEET POTATO
    {"crop_name_en":"sweet potato","crop_name_sw":"Viazi vitamu","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":700,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"sweet potato","crop_name_sw":"Viazi vitamu","market_name":"Mbeya Market","region":"Mbeya","price_tzs_kg":550,"price_date":TODAY,"source":"seed_data"},
    # KAHAWA / COFFEE
    {"crop_name_en":"coffee","crop_name_sw":"Kahawa","market_name":"Kilimanjaro Market","region":"Kilimanjaro","price_tzs_kg":4000,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"coffee","crop_name_sw":"Kahawa","market_name":"Mbeya Market","region":"Mbeya","price_tzs_kg":3800,"price_date":TODAY,"source":"seed_data"},
    # KOROSHO / CASHEW
    {"crop_name_en":"cashew","crop_name_sw":"Korosho","market_name":"Mtwara Market","region":"Mtwara","price_tzs_kg":4800,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"cashew","crop_name_sw":"Korosho","market_name":"Lindi Market","region":"Lindi","price_tzs_kg":5000,"price_date":TODAY,"source":"seed_data"},
    # KARANGA / GROUNDNUT
    {"crop_name_en":"groundnut","crop_name_sw":"Karanga","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":3000,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"groundnut","crop_name_sw":"Karanga","market_name":"Dodoma Central Market","region":"Dodoma","price_tzs_kg":2500,"price_date":TODAY,"source":"seed_data"},
    # AVOKADO
    {"crop_name_en":"avocado","crop_name_sw":"Avokado","market_name":"Arusha Central Market","region":"Arusha","price_tzs_kg":2000,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"avocado","crop_name_sw":"Avokado","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":2500,"price_date":TODAY,"source":"seed_data"},
    # EMBE / MANGO
    {"crop_name_en":"mango","crop_name_sw":"Embe","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":800,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"mango","crop_name_sw":"Embe","market_name":"Mtwara Market","region":"Mtwara","price_tzs_kg":400,"price_date":TODAY,"source":"seed_data"},
    # VIAZI / IRISH POTATO
    {"crop_name_en":"potato","crop_name_sw":"Viazi","market_name":"Arusha Central Market","region":"Arusha","price_tzs_kg":1000,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"potato","crop_name_sw":"Viazi","market_name":"Mbeya Market","region":"Mbeya","price_tzs_kg":900,"price_date":TODAY,"source":"seed_data"},
    # KABICHI / CABBAGE
    {"crop_name_en":"cabbage","crop_name_sw":"Kabichi","market_name":"Arusha Central Market","region":"Arusha","price_tzs_kg":800,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"cabbage","crop_name_sw":"Kabichi","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":1000,"price_date":TODAY,"source":"seed_data"},
    # SUKUMA WIKI / KALE
    {"crop_name_en":"kale","crop_name_sw":"Sukuma wiki","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":500,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"kale","crop_name_sw":"Sukuma wiki","market_name":"Mwanza Market","region":"Mwanza","price_tzs_kg":450,"price_date":TODAY,"source":"seed_data"},
    # SOYA
    {"crop_name_en":"soybean","crop_name_sw":"Soya","market_name":"Mbeya Market","region":"Mbeya","price_tzs_kg":1200,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"soybean","crop_name_sw":"Soya","market_name":"Morogoro Market","region":"Morogoro","price_tzs_kg":1100,"price_date":TODAY,"source":"seed_data"},
    # TIKITI MAJI / WATERMELON
    {"crop_name_en":"watermelon","crop_name_sw":"Tikiti maji","market_name":"Kariakoo — Dar es Salaam","region":"Dar es Salaam","price_tzs_kg":600,"price_date":TODAY,"source":"seed_data"},
    {"crop_name_en":"watermelon","crop_name_sw":"Tikiti maji","market_name":"Dodoma Central Market","region":"Dodoma","price_tzs_kg":500,"price_date":TODAY,"source":"seed_data"},
]

class MarketPriceScraper(BaseScraper):
    def __init__(self):
        super().__init__("Tanzania Market Prices",
                        "https://www.kilimo.go.tz", "market_prices")

    def _try_kilimo(self):
        """Attempt to scrape kilimo.go.tz price tables."""
        try:
            r = requests.get(self.url, headers=random_headers(), timeout=10)
            if r.status_code != 200:
                return False
        except Exception:
            return False

        log.info("kilimo.go.tz reachable — trying to find price data...")
        for path in ["/bei-za-mazao", "/market-prices", "/prices", "/soko", ""]:
            html = self.fetch_page(self.url + path)
            if not html:
                continue
            soup = self.parse(html)
            records = []
            for table in soup.find_all("table"):
                rows = table.find_all("tr")
                if len(rows) < 2:
                    continue
                for row in rows[1:]:
                    cells = [td.get_text(strip=True) for td in row.find_all("td")]
                    if len(cells) >= 3 and cells[0]:
                        price_raw = re.sub(r"[^\d]", "", cells[2]) if len(cells) > 2 else "0"
                        records.append({
                            "crop_name_sw": cells[0],
                            "crop_name_en": cells[0].lower(),
                            "market_name": cells[1] if len(cells) > 1 else "Tanzania",
                            "price_tzs_kg": int(price_raw) if price_raw else 0,
                            "price_date": TODAY,
                            "source": "kilimo.go.tz",
                        })
            if records:
                self.save_records(records)
                log.info(f"Scraped {len(records)} live price records")
                return True

        # Also try EAGC
        try:
            r2 = requests.get("https://www.eagc.org", headers=random_headers(), timeout=10)
            if r2.status_code == 200:
                html = self.fetch_page("https://www.eagc.org/prices")
                if html:
                    soup = self.parse(html)
                    for table in soup.find_all("table"):
                        rows = table.find_all("tr")
                        records = []
                        for row in rows[1:]:
                            cells = [td.get_text(strip=True) for td in row.find_all("td")]
                            if len(cells) >= 2 and cells[0]:
                                price_raw = re.sub(r"[^\d]", "", cells[-1])
                                records.append({
                                    "crop_name_en": cells[0].lower(),
                                    "crop_name_sw": cells[0],
                                    "market_name": cells[1] if len(cells) > 1 else "Tanzania",
                                    "price_tzs_kg": int(price_raw) if price_raw else 0,
                                    "price_date": TODAY,
                                    "source": "eagc.org",
                                })
                        if records:
                            self.save_records(records)
                            return True
        except Exception:
            pass

        return False

    def scrape(self):
        if not self._try_kilimo():
            log.info("Price sites unavailable — inserting comprehensive market price seed data...")
            saved = self.save_records(SEED_PRICES)
            log.info(f"Inserted {saved} market price records")

if __name__ == "__main__":
    MarketPriceScraper().run()
    print(f"Scraped market price records")
