import os, logging, random, time
from supabase import create_client, Client

SUPABASE_URL = "https://pbngmusrzvzycdjltrbs.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBibmdtdXNyenZ6eWNkamx0cmJzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5NDI5MTgsImV4cCI6MjA5MjUxODkxOH0.rd6RPnq4ySNP4fFwv1PLEw0govpfCmQ-WJlcslMizis"

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)
log = logging.getLogger("shamba_scraper")

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/119.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/118.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/119.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Safari/605.1.15",
]

def random_headers():
    return {
        "User-Agent": random.choice(USER_AGENTS),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
        "Accept-Encoding": "gzip, deflate",
        "Connection": "keep-alive",
    }

def sleep_politely():
    time.sleep(random.uniform(2, 5))

CROP_SW_TO_EN = {
    "mahindi": "maize", "nyanya": "tomato", "maharagwe": "beans",
    "pilipili": "pepper", "pilipili hoho": "bell pepper",
    "ndizi": "banana", "mchele": "rice", "muhogo": "cassava",
    "vitunguu": "onion", "kabichi": "cabbage", "karoti": "carrot",
    "alizeti": "sunflower", "pamba": "cotton", "kahawa": "coffee",
    "chai": "tea", "korosho": "cashew", "ngano": "wheat",
    "mtama": "sorghum", "choroko": "cowpea", "karanga": "groundnut",
    "soya": "soybean", "viazi": "potato", "viazi vitamu": "sweet potato",
    "embe": "mango", "nanasi": "pineapple", "papai": "papaya",
    "sukuma wiki": "kale", "bamia": "okra", "tango": "cucumber",
}
