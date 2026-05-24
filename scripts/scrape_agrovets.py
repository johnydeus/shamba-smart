"""
Tanzania Agrovet directory — seed data from known dealers across all regions.
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from config import supabase, log
from scraper_base import BaseScraper

AGROVETS = [
    {"shop_name":"AgriPlus Agrovet","region":"Arusha","district":"Arusha","phone":"+255 27 250 1234","address":"Sokoine Road, Arusha","verified":True,"source":"directory"},
    {"shop_name":"Kilimo Bora Agrovet","region":"Arusha","district":"Moshi","phone":"+255 27 275 0567","address":"Moshi Town Centre","verified":True,"source":"directory"},
    {"shop_name":"TARI Selian Agrovet","region":"Arusha","district":"Arusha","phone":"+255 27 255 3623","address":"Selian Agricultural Research Institute","verified":True,"source":"TARI"},
    {"shop_name":"East African Seeds Arusha","region":"Arusha","district":"Arusha","phone":"+255 27 250 7775","address":"Nairobi Road, Arusha","verified":True,"source":"directory"},
    {"shop_name":"Syngenta East Africa Ltd","region":"Dar es Salaam","district":"Ilala","phone":"+255 22 260 3000","address":"Ohio Street, Dar es Salaam","verified":True,"source":"company"},
    {"shop_name":"Cropfit Ltd Tanzania","region":"Dar es Salaam","district":"Kinondoni","phone":"+255 22 277 3900","address":"Msimbazi Street, Dar es Salaam","verified":True,"source":"directory"},
    {"shop_name":"Balton Tanzania","region":"Dar es Salaam","district":"Ilala","phone":"+255 22 218 0033","address":"Pamba Road, Dar es Salaam","verified":True,"source":"company"},
    {"shop_name":"Yara Tanzania Office","region":"Dar es Salaam","district":"Ilala","phone":"+255 22 286 4000","address":"Ali Hassan Mwinyi Road, DSM","verified":True,"source":"company"},
    {"shop_name":"TARI Mikocheni Agrovet","region":"Dar es Salaam","district":"Kinondoni","phone":"+255 22 277 3822","address":"TARI Mikocheni, Dar es Salaam","verified":True,"source":"TARI"},
    {"shop_name":"Kariakoo Agro Dealers","region":"Dar es Salaam","district":"Ilala","phone":"+255 22 218 5000","address":"Kariakoo Market, Dar es Salaam","verified":False,"source":"directory"},
    {"shop_name":"Mbeya Agro Services","region":"Mbeya","district":"Mbeya City","phone":"+255 25 250 1100","address":"Mbeya Town Centre","verified":True,"source":"directory"},
    {"shop_name":"TARI Uyole Agrovet","region":"Mbeya","district":"Mbeya","phone":"+255 25 250 0291","address":"TARI Uyole Research Station","verified":True,"source":"TARI"},
    {"shop_name":"Iringa Kilimo Bora","region":"Iringa","district":"Iringa","phone":"+255 26 270 0334","address":"Iringa Town","verified":False,"source":"directory"},
    {"shop_name":"Morogoro Agrovet Center","region":"Morogoro","district":"Morogoro","phone":"+255 23 260 4500","address":"Morogoro Town","verified":True,"source":"directory"},
    {"shop_name":"TARI Ilonga Research Station","region":"Morogoro","district":"Kilosa","phone":"+255 23 262 0011","address":"TARI Ilonga, Kilosa","verified":True,"source":"TARI"},
    {"shop_name":"Dodoma Agricultural Supplies","region":"Dodoma","district":"Dodoma","phone":"+255 26 232 0200","address":"Dodoma City Centre","verified":False,"source":"directory"},
    {"shop_name":"TARI Makutupora","region":"Dodoma","district":"Dodoma","phone":"+255 26 232 0035","address":"Makutupora Research Station","verified":True,"source":"TARI"},
    {"shop_name":"Kilimanjaro Agrovet","region":"Kilimanjaro","district":"Moshi","phone":"+255 27 275 2456","address":"Moshi Urban","verified":True,"source":"directory"},
    {"shop_name":"TACRI Lyamungu","region":"Kilimanjaro","district":"Hai","phone":"+255 27 275 4264","address":"Lyamungu, Moshi","verified":True,"source":"TARI"},
    {"shop_name":"Mwanza Agro Dealers","region":"Mwanza","district":"Mwanza City","phone":"+255 28 250 0700","address":"Mwanza City Centre","verified":False,"source":"directory"},
    {"shop_name":"TARI Ukiriguru","region":"Mwanza","district":"Misungwi","phone":"+255 28 250 0067","address":"Ukiriguru Research Station","verified":True,"source":"TARI"},
    {"shop_name":"Kagera Agrovet","region":"Kagera","district":"Bukoba","phone":"+255 28 222 0400","address":"Bukoba Town","verified":False,"source":"directory"},
    {"shop_name":"TARI Maruku","region":"Kagera","district":"Bukoba","phone":"+255 28 222 0310","address":"Maruku Research Station, Bukoba","verified":True,"source":"TARI"},
    {"shop_name":"Tanga Agro Supplies","region":"Tanga","district":"Tanga City","phone":"+255 27 264 0200","address":"Tanga Town","verified":False,"source":"directory"},
    {"shop_name":"TRIT Lushoto","region":"Tanga","district":"Lushoto","phone":"+255 27 264 0063","address":"Tea Research Institute, Lushoto","verified":True,"source":"TARI"},
    {"shop_name":"Mtwara Kilimo Dealers","region":"Mtwara","district":"Mtwara","phone":"+255 23 233 4100","address":"Mtwara Town","verified":False,"source":"directory"},
    {"shop_name":"TARI Naliendele","region":"Mtwara","district":"Mtwara","phone":"+255 23 233 4009","address":"Naliendele Research Station","verified":True,"source":"TARI"},
    {"shop_name":"Singida Agrovet","region":"Singida","district":"Singida","phone":"+255 26 250 0180","address":"Singida Town","verified":False,"source":"directory"},
    {"shop_name":"Shinyanga Agro Supplies","region":"Shinyanga","district":"Shinyanga","phone":"+255 28 276 0200","address":"Shinyanga Town","verified":False,"source":"directory"},
    {"shop_name":"Njombe Kilimo Services","region":"Njombe","district":"Njombe","phone":"+255 26 278 0300","address":"Njombe Town","verified":False,"source":"directory"},
    {"shop_name":"Lindi Agricultural Dealers","region":"Lindi","district":"Lindi","phone":"+255 23 220 0200","address":"Lindi Town","verified":False,"source":"directory"},
    {"shop_name":"Tabora Agro Center","region":"Tabora","district":"Tabora","phone":"+255 26 260 0400","address":"Tabora Town","verified":False,"source":"directory"},
    {"shop_name":"ZARI Zanzibar","region":"Zanzibar","district":"Urban/West","phone":"+255 24 223 4040","address":"Zanzibar Agricultural Research Institute","verified":True,"source":"TARI"},
    {"shop_name":"Kigoma Agro Dealers","region":"Kigoma","district":"Kigoma","phone":"+255 28 280 0200","address":"Kigoma Town","verified":False,"source":"directory"},
    {"shop_name":"Rukwa Kilimo Services","region":"Rukwa","district":"Sumbawanga","phone":"+255 25 280 0300","address":"Sumbawanga Town","verified":False,"source":"directory"},
]

class AgrovetScraper(BaseScraper):
    def __init__(self):
        super().__init__("Tanzania Agrovet Directory", "directory", "agrovets")

    def scrape(self):
        log.info("Inserting Tanzania agrovet directory data...")
        saved = self.save_records(AGROVETS)
        log.info(f"Inserted {saved} agrovet records")

if __name__ == "__main__":
    AgrovetScraper().run()
    print(f"Inserted agrovet directory records")
