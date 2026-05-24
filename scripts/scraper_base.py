import requests, time, random, logging
from datetime import datetime
from bs4 import BeautifulSoup
from config import supabase, random_headers, sleep_politely, log

class BaseScraper:
    def __init__(self, name, url, table):
        self.name = name
        self.url = url
        self.table = table
        self.records_scraped = 0
        self.log_id = None

    def _start_log(self):
        try:
            res = supabase.table("scrape_logs").insert({
                "target_name": self.name,
                "target_url": self.url,
                "status": "running",
                "started_at": datetime.utcnow().isoformat(),
            }).execute()
            self.log_id = res.data[0]["id"] if res.data else None
        except Exception as e:
            log.warning(f"Could not start scrape log: {e}")

    def _end_log(self, status, error=None):
        if not self.log_id:
            return
        try:
            supabase.table("scrape_logs").update({
                "status": status,
                "records_scraped": self.records_scraped,
                "error_message": str(error) if error else None,
                "completed_at": datetime.utcnow().isoformat(),
            }).eq("id", self.log_id).execute()
        except Exception as e:
            log.warning(f"Could not end scrape log: {e}")

    def fetch_page(self, url=None, retries=3):
        target = url or self.url
        for attempt in range(retries):
            try:
                sleep_politely()
                r = requests.get(target, headers=random_headers(), timeout=15)
                if r.status_code == 200:
                    return r.text
                elif r.status_code == 403:
                    log.warning(f"Blocked (403) on {target} — trying different agent")
                    time.sleep(5)
                else:
                    log.warning(f"HTTP {r.status_code} on {target}")
            except Exception as e:
                log.warning(f"Attempt {attempt+1} failed for {target}: {e}")
                time.sleep(3)
        return None

    def parse(self, html):
        return BeautifulSoup(html, "lxml") if html else None

    def save_records(self, records):
        saved = 0
        for rec in records:
            try:
                supabase.table(self.table).insert(rec).execute()
                saved += 1
            except Exception as e:
                log.warning(f"Insert failed: {e} — {list(rec.values())[:2]}")
        self.records_scraped += saved
        return saved

    def run(self):
        self._start_log()
        try:
            log.info(f"Starting scraper: {self.name}")
            self.scrape()
            log.info(f"✓ {self.name}: {self.records_scraped} records saved")
            self._end_log("success")
        except Exception as e:
            log.error(f"✗ {self.name} failed: {e}")
            self._end_log("error", e)

    def scrape(self):
        raise NotImplementedError
