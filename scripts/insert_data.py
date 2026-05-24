"""
Insert all seed data into existing Supabase tables using correct column schemas.
Runs autonomously — handles all tables, skips duplicates, reports results.
"""
import sys, os, warnings
warnings.filterwarnings('ignore')
sys.path.insert(0, os.path.dirname(__file__))
from config import supabase, log
from datetime import date

TODAY = date.today().isoformat()

# ── PESTICIDES (matches actual schema) ────────────────────────────────────────
PESTICIDES = [
    {"brand_name":"Coragen 20SC","active_ingredient":"Chlorantraniliprole 200g/L","category":"Insecticide",
     "target_pests":"Fall Armyworm, Stem borers, Leaf miners","target_crops":["maize","tomato","rice","cotton"],
     "ml_per_15l":"20ml","phi_days":1,"price_tzs":35000,"tpri_registered":True,"manufacturer":"FMC Corporation",
     "description_sw":"Dawa bora kwa viwavi wa jeshi. Tumia ml 20 kwa dumu la 15L.","safety_sw":"Vaa nguo za kinga. Usioge kwenye mto baada ya kutumia."},
    {"brand_name":"Dithane M-45","active_ingredient":"Mancozeb 80%","category":"Fungicide",
     "target_disease":"Blight, Leaf spot, Downy mildew","target_crops":["tomato","potato","onion","beans"],
     "ml_per_15l":"40g","phi_days":7,"price_tzs":12000,"tpri_registered":True,"manufacturer":"Dow AgroSciences",
     "description_sw":"Unga wa kuua ukungu kwa nyanya na viazi. Tumia gramu 40 kwa dumu la 15L.","safety_sw":"Epuka kupumua unga. Osha mikono kabla ya kula."},
    {"brand_name":"Emamectin 5% SG","active_ingredient":"Emamectin Benzoate 5%","category":"Insecticide",
     "target_pests":"Diamondback moth, Fall Armyworm, Caterpillars","target_crops":["maize","tomato","cabbage"],
     "ml_per_15l":"10g","phi_days":3,"price_tzs":18000,"tpri_registered":True,"manufacturer":"Syngenta",
     "description_sw":"Dawa kali kwa viwavi na wadudu wanaokula majani.","safety_sw":"Sumu kali — vaa glovu na barakoa daima."},
    {"brand_name":"Kocide 2000","active_ingredient":"Copper Hydroxide 53.8%","category":"Fungicide",
     "target_disease":"Bacterial blight, Angular leaf spot, Coffee berry disease","target_crops":["coffee","banana","tomato","beans"],
     "ml_per_15l":"30g","phi_days":14,"price_tzs":22000,"tpri_registered":True,"manufacturer":"DuPont",
     "description_sw":"Dawa ya shaba kwa magonjwa ya bakteria na ukungu. Inafaa kwa kahawa na ndizi.","safety_sw":"Haidhuru sana lakini vaa nguo za kinga."},
    {"brand_name":"Karate 5EC","active_ingredient":"Lambda-cyhalothrin 5%","category":"Insecticide",
     "target_pests":"Aphids, Thrips, Bollworm, Whitefly","target_crops":["maize","cotton","beans","vegetables"],
     "ml_per_15l":"20ml","phi_days":7,"price_tzs":8500,"tpri_registered":True,"manufacturer":"Syngenta",
     "description_sw":"Dawa ya haraka kwa wadudu wengi. Inamaliza wadudu ndani ya masaa machache.","safety_sw":"Hatari kwa nyuki. Usinyunyize wakati wa maua. Vaa nguo za kinga."},
    {"brand_name":"Confidor 200SL","active_ingredient":"Imidacloprid 200g/L","category":"Insecticide",
     "target_pests":"Whitefly, Aphids, Thrips, Leafhoppers","target_crops":["tomato","cotton","vegetables","rice"],
     "ml_per_15l":"10ml","phi_days":14,"price_tzs":15000,"tpri_registered":True,"manufacturer":"Bayer CropScience",
     "description_sw":"Dawa ya ndani ya mmea — inafanya mmea uwe na sumu kwa wadudu.","safety_sw":"Hatari kwa nyuki na wadudu wanaoumba asali. Epuka kutumia wakati wa maua."},
    {"brand_name":"Roundup 360SL","active_ingredient":"Glyphosate 360g/L","category":"Herbicide",
     "target_pests":"Nyasi, Magugu mapana, Magugu ya kudumu","target_crops":["maize","sugarcane","banana","coffee"],
     "ml_per_15l":"50ml","phi_days":0,"price_tzs":9000,"tpri_registered":True,"manufacturer":"Bayer",
     "description_sw":"Dawa ya kuua magugu yote kabla ya kupanda. USINYUNYIZE kwenye mazao yaliyopanda.","safety_sw":"Sumu kwa wanyama wa majini. Usinyunyize karibu na mto. Vaa glovu."},
    {"brand_name":"Ridomil Gold 68WG","active_ingredient":"Metalaxyl-M 4%+Mancozeb 64%","category":"Fungicide",
     "target_disease":"Phytophthora, Downy mildew, Damping off","target_crops":["tomato","potato","onion","pepper"],
     "ml_per_15l":"35g","phi_days":7,"price_tzs":28000,"tpri_registered":True,"manufacturer":"Syngenta",
     "description_sw":"Dawa bora kwa ugonjwa wa kuoza kwa nyanya na viazi. Inafanya kazi ndani ya mmea.","safety_sw":"Osha mikono vizuri. Hifadhi mbali na watoto."},
    {"brand_name":"Tilt 250EC","active_ingredient":"Propiconazole 250g/L","category":"Fungicide",
     "target_disease":"Rust, Powdery mildew, Leaf blight","target_crops":["wheat","maize","coffee","banana"],
     "ml_per_15l":"10ml","phi_days":14,"price_tzs":24000,"tpri_registered":True,"manufacturer":"Syngenta",
     "description_sw":"Dawa ya ukungu kwa ngano na mahindi. Inaingia ndani ya mmea.","safety_sw":"Vaa nguo za kinga. Usile wala kunywa wakati wa kutumia."},
    {"brand_name":"Amistar 250SC","active_ingredient":"Azoxystrobin 250g/L","category":"Fungicide",
     "target_disease":"Early blight, Late blight, Anthracnose","target_crops":["tomato","beans","rice","wheat"],
     "ml_per_15l":"8ml","phi_days":7,"price_tzs":32000,"tpri_registered":True,"manufacturer":"Syngenta",
     "description_sw":"Dawa ya kisasa ya ukungu inayofanya kazi kwa magonjwa mengi ya majani.","safety_sw":"Hifadhi mahali pa baridi. Vaa glovu na miwani."},
    {"brand_name":"Tracer 480SC","active_ingredient":"Spinosad 480g/L","category":"Insecticide",
     "target_pests":"Fall Armyworm, Thrips, Diamondback moth","target_crops":["vegetables","cotton","maize","tomato"],
     "ml_per_15l":"3ml","phi_days":1,"price_tzs":42000,"tpri_registered":True,"manufacturer":"Dow AgroSciences",
     "description_sw":"Dawa ya asili (spinosad). Salama kwa mazingira. Inafaa kwa kilimo hai.","safety_sw":"Hatari kidogo sana kwa binadamu. Kaa mbali na nyuki."},
    {"brand_name":"Score 250EC","active_ingredient":"Difenoconazole 250g/L","category":"Fungicide",
     "target_disease":"Leaf spot, Alternaria blight, Scab","target_crops":["tomato","onion","beans","potato"],
     "ml_per_15l":"10ml","phi_days":7,"price_tzs":26000,"tpri_registered":True,"manufacturer":"Syngenta",
     "description_sw":"Dawa ya ukungu inayodumu muda mrefu. Inafaa kwa vitunguu na nyanya.","safety_sw":"Vaa nguo za kinga. Osha baada ya kazi."},
    {"brand_name":"Decis 25EC","active_ingredient":"Deltamethrin 25g/L","category":"Insecticide",
     "target_pests":"Aphids, Whitefly, Bollworm, Pod borers","target_crops":["cotton","maize","beans","coffee"],
     "ml_per_15l":"10ml","phi_days":3,"price_tzs":7500,"tpri_registered":True,"manufacturer":"Bayer CropScience",
     "description_sw":"Dawa ya haraka ya kuua wadudu wengi. Bei ya chini. Inapatikana kila mahali.","safety_sw":"Sumu ya wastani. Vaa nguo za kinga daima."},
    {"brand_name":"Stomp 33EC","active_ingredient":"Pendimethalin 330g/L","category":"Herbicide",
     "target_pests":"Annual grasses, Broadleaf weeds","target_crops":["maize","beans","cotton","onion"],
     "ml_per_15l":"35ml","phi_days":0,"price_tzs":16000,"tpri_registered":True,"manufacturer":"BASF",
     "description_sw":"Dawa ya kuzuia magugu kabla hayajachipua. Nyunyiza baada ya kupanda mbegu.","safety_sw":"Usinyunyize mbeguni. Vaa glovu na nguo ndefu."},
    {"brand_name":"Selecron 500EC","active_ingredient":"Profenofos 500g/L","category":"Insecticide",
     "target_pests":"Bollworm, Aphids, Mites, Thrips","target_crops":["cotton","tomato","pepper","beans"],
     "ml_per_15l":"20ml","phi_days":10,"price_tzs":13000,"tpri_registered":True,"manufacturer":"Syngenta",
     "description_sw":"Dawa kwa wadudu wa pamba na nyanya. Pia inafanya kazi kwa utitiri.","safety_sw":"Sumu kali. Vaa nguo zote za kinga. Usifanye kazi peke yako."},
    {"brand_name":"Mospilan 20SP","active_ingredient":"Acetamiprid 20%","category":"Insecticide",
     "target_pests":"Whitefly, Aphids, Thrips, Leafminers","target_crops":["tomato","pepper","eggplant","cotton"],
     "ml_per_15l":"5g","phi_days":3,"price_tzs":20000,"tpri_registered":True,"manufacturer":"Nippon Soda",
     "description_sw":"Dawa ya ndani ya mmea kwa wadudu wadogo wanaosucking.","safety_sw":"Hatari kwa nyuki. Usinyunyize wakati wa maua. Epuka kuvuta pumzi ya dawa."},
    {"brand_name":"Voliam Flexi 300SC","active_ingredient":"Thiamethoxam+Chlorantraniliprole","category":"Insecticide",
     "target_pests":"Fall Armyworm, Stem borers, Sucking pests","target_crops":["maize","rice","sugarcane","vegetables"],
     "ml_per_15l":"10ml","phi_days":3,"price_tzs":45000,"tpri_registered":True,"manufacturer":"Syngenta",
     "description_sw":"Dawa mbili kwa moja — inua wadudu wa nje na wa ndani ya mmea.","safety_sw":"Vaa nguo za kinga zote. Usinyunyize karibu na maji."},
    {"brand_name":"Lannate LV","active_ingredient":"Methomyl 215g/L","category":"Insecticide",
     "target_pests":"Caterpillars, Aphids, Thrips, Whitefly","target_crops":["tomato","cotton","vegetables"],
     "ml_per_15l":"15ml","phi_days":3,"price_tzs":11000,"tpri_registered":True,"manufacturer":"DuPont",
     "description_sw":"Dawa ya nguvu ya wadudu. Inamaliza haraka. Usitumie mara nyingi sana ili usijenga kinga.","safety_sw":"Sumu kali SANA. Vaa nguo zote za kinga. Kaa mbali na watoto na wanyama."},
    {"brand_name":"Nativo 75WG","active_ingredient":"Trifloxystrobin 25%+Tebuconazole 50%","category":"Fungicide",
     "target_disease":"Rust, Blight, Leaf spot, Fusarium","target_crops":["maize","wheat","coffee","rice"],
     "ml_per_15l":"3g","phi_days":14,"price_tzs":38000,"tpri_registered":True,"manufacturer":"Bayer CropScience",
     "description_sw":"Dawa mbili kwa moja kwa ukungu. Inafanya kazi kwa muda mrefu zaidi.","safety_sw":"Vaa nguo za kinga. Osha vizuri baada ya kazi."},
    {"brand_name":"Gramoxone 200SL","active_ingredient":"Paraquat 200g/L","category":"Herbicide",
     "target_pests":"Weeds of all types — contact action","target_crops":["maize","rice","banana","sugarcane"],
     "ml_per_15l":"50ml","phi_days":0,"price_tzs":8000,"tpri_registered":True,"manufacturer":"Syngenta",
     "description_sw":"Dawa ya kuua magugu yote haraka sana. KUNYWA = KIFO. Usiiache wazi.","safety_sw":"HATARI KUBWA SANA. Hakuna dawa ya kuzuia sumu hii. Vaa glovu, nguo ndefu, miwani DAIMA."},
    {"brand_name":"Cruiser 350FS","active_ingredient":"Thiamethoxam 350g/L","category":"Insecticide",
     "target_pests":"Soil pests, Wireworm, Aphids (systemic)","target_crops":["maize","sunflower","cotton","soybean"],
     "ml_per_15l":"5ml","phi_days":21,"price_tzs":25000,"tpri_registered":True,"manufacturer":"Syngenta",
     "description_sw":"Dawa ya kupaka mbegu kabla ya kupanda. Inalinda mmea wiki 4-6 za kwanza.","safety_sw":"Usipake mbegu bila glovu. Hifadhi mbegu zilizopakwa mbali na chakula."},
    {"brand_name":"Dynamec 18EC","active_ingredient":"Abamectin 18g/L","category":"Insecticide/Acaricide",
     "target_pests":"Spider mites, Leafminers, Thrips","target_crops":["tomato","beans","cucumber","pepper"],
     "ml_per_15l":"10ml","phi_days":3,"price_tzs":29000,"tpri_registered":True,"manufacturer":"Syngenta",
     "description_sw":"Dawa bora kwa utitiri (mites) na wadudu wadogo wa majani.","safety_sw":"Sumu ya wastani. Epuka kugusa au kumeza."},
    {"brand_name":"Atranex 90WG","active_ingredient":"Atrazine 90%","category":"Herbicide",
     "target_pests":"Annual weeds in maize","target_crops":["maize","sugarcane","sorghum"],
     "ml_per_15l":"5g","phi_days":0,"price_tzs":6500,"tpri_registered":True,"manufacturer":"Nufarm",
     "description_sw":"Dawa ya magugu kwa mahindi. Nyunyiza wakati wa kupanda au kabla magugu hayajachipua.","safety_sw":"Hatari kwa mazao mengine. Usinyunyize karibu na miti ya matunda au mboga."},
    {"brand_name":"Bavistin 50WP","active_ingredient":"Carbendazim 50%","category":"Fungicide",
     "target_disease":"Damping off, Fusarium wilt, Botrytis","target_crops":["beans","tomato","rice","wheat"],
     "ml_per_15l":"20g","phi_days":14,"price_tzs":9500,"tpri_registered":True,"manufacturer":"BASF",
     "description_sw":"Unga wa ukungu wa bei nafuu. Inafaa kwa magonjwa ya shina na mizizi.","safety_sw":"Vaa barakoa ukipanga unga. Hifadhi mahali pakavu."},
    {"brand_name":"Bayfolan Forte","active_ingredient":"NPK 11-8-6 + micronutrients","category":"Foliar Fertiliser",
     "target_pests":"Nutrient deficiency","target_crops":["vegetables","fruit","coffee","flowers"],
     "ml_per_15l":"30ml","phi_days":0,"price_tzs":38000,"tpri_registered":False,"manufacturer":"Bayer CropScience",
     "description_sw":"Mbolea ya majani inayoongeza nguvu ya mmea haraka. Tumia na dawa nyingine.","safety_sw":"Salama — lakini epuka kunywa au kugusa macho."},
    {"brand_name":"Force 1.5G","active_ingredient":"Tefluthrin 1.5%","category":"Insecticide",
     "target_pests":"Soil-borne pests, Rootworm, Wireworm","target_crops":["maize","sorghum","sunflower"],
     "ml_per_15l":"granule — apply in furrow at planting","phi_days":0,"price_tzs":14000,"tpri_registered":True,"manufacturer":"Syngenta",
     "description_sw":"Chembe cha ardhi kwa wadudu wa udongo. Weka kwenye mfereji wa kupanda.","safety_sw":"Usimeze chembe. Osha mikono baada ya kupanda."},
    {"brand_name":"Dursban 48EC","active_ingredient":"Chlorpyrifos 480g/L","category":"Insecticide",
     "target_pests":"Stem borers, Soil pests, Aphids","target_crops":["maize","beans","groundnut"],
     "ml_per_15l":"20ml","phi_days":14,"price_tzs":9500,"tpri_registered":True,"manufacturer":"Dow AgroSciences",
     "description_sw":"Dawa ya kawaida kwa wadudu. Inafaa kwa wadudu wa shina na ardhi.","safety_sw":"Sumu ya wastani. Vaa nguo za kinga. Epuka kumwaga kwenye maji."},
    {"brand_name":"Copper Champion 77WP","active_ingredient":"Copper Oxychloride 77%","category":"Fungicide",
     "target_disease":"Downy mildew, Late blight, Septoria","target_crops":["tomato","potato","onion","grapes"],
     "ml_per_15l":"40g","phi_days":7,"price_tzs":11000,"tpri_registered":True,"manufacturer":"Various",
     "description_sw":"Unga wa shaba wa bei nafuu kwa magonjwa ya ukungu. Inafanya kazi vizuri ukichanganya na maji ya baridi.","safety_sw":"Epuka kuingizwa machoni. Osha nguo baada ya kufanya kazi."},
]

MARKET_PRICES = [
    {"crop_name":"Mahindi","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":480,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Mahindi","market_name":"Arusha Central Market","price_tzs_kg":420,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Mahindi","market_name":"Mbeya Market","price_tzs_kg":380,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Mahindi","market_name":"Dodoma Central Market","price_tzs_kg":390,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Mahindi","market_name":"Mwanza Market","price_tzs_kg":460,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Nyanya","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":1200,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Nyanya","market_name":"Arusha Central Market","price_tzs_kg":900,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Nyanya","market_name":"Mbeya Market","price_tzs_kg":800,"trend":"inashuka","source":"seed_data","price_date":TODAY},
    {"crop_name":"Nyanya","market_name":"Mwanza Market","price_tzs_kg":1100,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Maharagwe","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":2200,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Maharagwe","market_name":"Arusha Central Market","price_tzs_kg":1900,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Mchele","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":1800,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Mchele","market_name":"Morogoro Market","price_tzs_kg":1650,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Mchele","market_name":"Mwanza Market","price_tzs_kg":1750,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Vitunguu","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":1800,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Vitunguu","market_name":"Arusha Central Market","price_tzs_kg":1600,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Karoti","market_name":"Arusha Central Market","price_tzs_kg":1200,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Karoti","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":1400,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Ndizi","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":600,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Ndizi","market_name":"Arusha Central Market","price_tzs_kg":500,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Muhogo","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":350,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Muhogo","market_name":"Dodoma Central Market","price_tzs_kg":320,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Pamba","market_name":"Mwanza Market","price_tzs_kg":1150,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Alizeti","market_name":"Dodoma Central Market","price_tzs_kg":1400,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Alizeti","market_name":"Mbeya Market","price_tzs_kg":1300,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Viazi vitamu","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":700,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Kahawa","market_name":"Kilimanjaro Market","price_tzs_kg":4000,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Korosho","market_name":"Mtwara Market","price_tzs_kg":4800,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Korosho","market_name":"Lindi Market","price_tzs_kg":5000,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Karanga","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":3000,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Soya","market_name":"Mbeya Market","price_tzs_kg":1200,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Avokado","market_name":"Arusha Central Market","price_tzs_kg":2000,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Embe","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":800,"trend":"inapanda","source":"seed_data","price_date":TODAY},
    {"crop_name":"Viazi","market_name":"Arusha Central Market","price_tzs_kg":1000,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Kabichi","market_name":"Arusha Central Market","price_tzs_kg":800,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Sukuma wiki","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":500,"trend":"imara","source":"seed_data","price_date":TODAY},
    {"crop_name":"Tikiti maji","market_name":"Kariakoo — Dar es Salaam","price_tzs_kg":600,"trend":"imara","source":"seed_data","price_date":TODAY},
]

AGROVETS = [
    {"shop_name":"AgriPlus Agrovet","region":"Arusha","district":"Arusha","phone":"+255 27 250 1234","verified":True,"source":"directory"},
    {"shop_name":"TARI Selian","region":"Arusha","district":"Arusha","phone":"+255 27 255 3623","verified":True,"source":"TARI"},
    {"shop_name":"East African Seeds Arusha","region":"Arusha","district":"Arusha","phone":"+255 27 250 7775","verified":True,"source":"company"},
    {"shop_name":"Syngenta East Africa","region":"Dar es Salaam","district":"Ilala","phone":"+255 22 260 3000","verified":True,"source":"company"},
    {"shop_name":"Balton Tanzania","region":"Dar es Salaam","district":"Ilala","phone":"+255 22 218 0033","verified":True,"source":"company"},
    {"shop_name":"Yara Tanzania","region":"Dar es Salaam","district":"Ilala","phone":"+255 22 286 4000","verified":True,"source":"company"},
    {"shop_name":"TARI Mikocheni","region":"Dar es Salaam","district":"Kinondoni","phone":"+255 22 277 3822","verified":True,"source":"TARI"},
    {"shop_name":"Mbeya Agro Services","region":"Mbeya","district":"Mbeya City","phone":"+255 25 250 1100","verified":True,"source":"directory"},
    {"shop_name":"TARI Uyole","region":"Mbeya","district":"Mbeya","phone":"+255 25 250 0291","verified":True,"source":"TARI"},
    {"shop_name":"Morogoro Agrovet Center","region":"Morogoro","district":"Morogoro","phone":"+255 23 260 4500","verified":True,"source":"directory"},
    {"shop_name":"TARI Ilonga","region":"Morogoro","district":"Kilosa","phone":"+255 23 262 0011","verified":True,"source":"TARI"},
    {"shop_name":"Dodoma Agricultural Supplies","region":"Dodoma","district":"Dodoma","phone":"+255 26 232 0200","verified":False,"source":"directory"},
    {"shop_name":"TARI Makutupora","region":"Dodoma","district":"Dodoma","phone":"+255 26 232 0035","verified":True,"source":"TARI"},
    {"shop_name":"Kilimanjaro Agrovet","region":"Kilimanjaro","district":"Moshi","phone":"+255 27 275 2456","verified":True,"source":"directory"},
    {"shop_name":"TACRI Lyamungu","region":"Kilimanjaro","district":"Hai","phone":"+255 27 275 4264","verified":True,"source":"TARI"},
    {"shop_name":"TARI Ukiriguru","region":"Mwanza","district":"Misungwi","phone":"+255 28 250 0067","verified":True,"source":"TARI"},
    {"shop_name":"TARI Maruku Bukoba","region":"Kagera","district":"Bukoba","phone":"+255 28 222 0310","verified":True,"source":"TARI"},
    {"shop_name":"Tanga Agro Supplies","region":"Tanga","district":"Tanga City","phone":"+255 27 264 0200","verified":False,"source":"directory"},
    {"shop_name":"TARI Naliendele","region":"Mtwara","district":"Mtwara","phone":"+255 23 233 4009","verified":True,"source":"TARI"},
    {"shop_name":"ZARI Zanzibar","region":"Zanzibar","district":"Urban/West","phone":"+255 24 223 4040","verified":True,"source":"TARI"},
    {"shop_name":"Iringa Kilimo Bora","region":"Iringa","district":"Iringa","phone":"+255 26 270 0334","verified":False,"source":"directory"},
    {"shop_name":"Njombe Kilimo Services","region":"Njombe","district":"Njombe","phone":"+255 26 278 0300","verified":False,"source":"directory"},
    {"shop_name":"Singida Agrovet","region":"Singida","district":"Singida","phone":"+255 26 250 0180","verified":False,"source":"directory"},
    {"shop_name":"Tabora Agro Center","region":"Tabora","district":"Tabora","phone":"+255 26 260 0400","verified":False,"source":"directory"},
    {"shop_name":"Kigoma Agro Dealers","region":"Kigoma","district":"Kigoma","phone":"+255 28 280 0200","verified":False,"source":"directory"},
]

def insert_all():
    results = {}

    # Pesticides
    ok = 0
    for p in PESTICIDES:
        try:
            supabase.table("pesticides").insert(p).execute()
            ok += 1
        except Exception as e:
            if "duplicate" not in str(e).lower():
                log.warning(f"pesticides insert: {str(e)[:60]}")
    results["pesticides"] = ok
    log.info(f"pesticides: {ok} records inserted")

    # Market prices
    ok = 0
    for p in MARKET_PRICES:
        try:
            supabase.table("market_prices").insert(p).execute()
            ok += 1
        except Exception as e:
            if "duplicate" not in str(e).lower():
                log.warning(f"market_prices insert: {str(e)[:60]}")
    results["market_prices"] = ok
    log.info(f"market_prices: {ok} records inserted")

    # Agrovets
    ok = 0
    for a in AGROVETS:
        try:
            supabase.table("agrovets").insert(a).execute()
            ok += 1
        except Exception as e:
            if "duplicate" not in str(e).lower():
                log.warning(f"agrovets insert: {str(e)[:60]}")
    results["agrovets"] = ok
    log.info(f"agrovets: {ok} records inserted")

    return results

if __name__ == "__main__":
    log.info("Inserting all data into existing Supabase tables...")
    results = insert_all()
    total = sum(results.values())
    print("\n" + "="*50)
    print("  DATA INSERTION COMPLETE")
    print("="*50)
    for table, count in results.items():
        print(f"  ✓ {table:<20} {count:>4} records")
    print(f"  Total: {total} records inserted")
    print("="*50)
