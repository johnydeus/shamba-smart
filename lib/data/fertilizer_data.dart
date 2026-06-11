// ─────────────────────────────────────────────────────────────────────────────
// FERTILIZER & CROP PRODUCTION STANDARDS — Table 9
//
// Chanzo: "Mwongozo wa Uzalishaji Mazao Kulingana na Kanda za Kilimo za
// Kiikolojia" — Wizara ya Kilimo Tanzania, Machi 2022
//
// All values are per hectare unless stated otherwise.
// fertilizers: map of fertilizer type → kg/ha (or [min, max] kg/ha range)
// ─────────────────────────────────────────────────────────────────────────────

class FertilizerData {
  FertilizerData._();

  static const String source = 'Wizara ya Kilimo Tanzania, 2022 — Jedwali 9';

  // Indicative retail prices TZS per kg (editable; subsidised market 2025/26)
  static const Map<String, int> fertilizerPriceTzsPerKg = {
    'DAP': 1400,
    'UREA': 1100,
    'TSP': 1300,
    'CAN': 1000,
    'NPK': 1200,
    'SA': 900,
    'Samadi': 100,
  };

  // Indicative farm-gate crop prices TZS per kg (for revenue estimates)
  static const Map<String, int> cropPriceTzsPerKg = {
    'Mahindi': 700, 'Mpunga': 1500, 'Mtama': 800, 'Uwele': 900,
    'Ulezi': 1200, 'Ngano': 1100, 'Maharage': 2500, 'Kunde': 1800,
    'Mbaazi': 1600, 'Soya': 1500, 'Dengu': 2200, 'Karanga': 2400,
    'Alizeti': 1100, 'Ufuta': 3000, 'Pamba': 1100, 'Tumbaku': 4500,
    'Kahawa arabika': 6000, 'Kahawa robusta': 4000, 'Chai': 350,
    'Korosho': 3500, 'Muhogo': 500, 'Viazi vitamu': 600,
    'Viazi mviringo': 900, 'Ndizi': 700, 'Nyanya': 1200, 'Kabichi': 500,
    'Vitunguu': 1800, 'Bilinganya': 800, 'Bamia': 1500, 'Karoti': 1000,
    'Matango': 800, 'Tikiti maji': 600, 'Nanasi': 800, 'Papai': 600,
    'Embe': 800, 'Michungwa': 700, 'Parachichi': 1500, 'Miwa': 100,
    'Pareto': 3500, 'Mkonge': 800, 'Michikichi': 600,
  };

  // ── TABLE 9: All 41 crops ──────────────────────────────────────────────────
  static const List<Map<String, dynamic>> crops = [
    {
      'jina': 'Kahawa arabika', 'jinaEn': 'Arabica Coffee',
      'spacing': '2.7m x 2.7m', 'spacingRow': 2.7, 'spacingPlant': 2.7,
      'seedRate': 'Miche',
      'fertilizers': {'Samadi': 20, 'CAN': 120, 'DAP': 100},
      'fertilizerNote': 'Samadi kilo 20 kwa shina + CAN 120 + DAP 100',
      'yieldNow': 0.65, 'yieldPotential': 2.5, 'yieldUnit': 't/ha',
      'plantsPerHa': [1330, 1330], 'maturityMonths': [36, 48],
    },
    {
      'jina': 'Kahawa robusta', 'jinaEn': 'Robusta Coffee',
      'spacing': '3.3m x 3.3m', 'spacingRow': 3.3, 'spacingPlant': 3.3,
      'seedRate': 'Miche',
      'fertilizers': {'Samadi': 20, 'CAN': 120, 'DAP': 100},
      'yieldNow': 1.0, 'yieldPotential': 2.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [1075, 1075], 'maturityMonths': [36, 60],
    },
    {
      'jina': 'Chai', 'jinaEn': 'Tea',
      'spacing': '0.9m x 0.6m', 'spacingRow': 0.9, 'spacingPlant': 0.6,
      'seedRate': 'Vipando',
      'fertilizers': {'TSP': 50, 'UREA': 250},
      'fertilizerNote': 'P: kilo 50, N: kilo 250 kwa hekta',
      'yieldNow': 1.55, 'yieldPotential': 3.5, 'yieldUnit': 't/ha',
      'plantsPerHa': [5000, 9760], 'maturityMonths': [24, 48],
    },
    {
      'jina': 'Korosho', 'jinaEn': 'Cashew',
      'spacing': '12m x 12m', 'spacingRow': 12.0, 'spacingPlant': 12.0,
      'seedRate': 'Miche',
      'fertilizers': {'Samadi': 20},
      'fertilizerNote': 'Samadi kilo 20 kwa mita ya mraba',
      'yieldNow': 0.5, 'yieldPotential': 1.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [69, 69], 'maturityMonths': [36, 48],
    },
    {
      'jina': 'Pamba', 'jinaEn': 'Cotton',
      'spacing': '0.9m x 0.3m', 'spacingRow': 0.9, 'spacingPlant': 0.3,
      'seedRate': '25 kg/ha', 'seedRateKgHa': [25, 25],
      'fertilizers': {'TSP': 15, 'UREA': 30},
      'fertilizerNote': 'P: kilo 15, N: kilo 30 kwa hekta',
      'yieldNow': 1.5, 'yieldPotential': 4.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [37000, 37000], 'maturityMonths': [6, 6],
    },
    {
      'jina': 'Tumbaku', 'jinaEn': 'Tobacco',
      'spacing': '1m x 0.6m', 'spacingRow': 1.0, 'spacingPlant': 0.6,
      'seedRate': '1.2 kg/ha', 'seedRateKgHa': [1.2, 1.2],
      'fertilizers': {'TSP': 38.7, 'UREA': 33.75},
      'fertilizerNote': 'P: kilo 38.7, N: kilo 33.75 kwa hekta',
      'yieldNow': 1.0, 'yieldPotential': 2.5, 'yieldUnit': 't/ha',
      'plantsPerHa': [16600, 16600], 'maturityMonths': [3, 4],
    },
    {
      'jina': 'Miwa', 'jinaEn': 'Sugarcane',
      'spacing': 'Mstari miwili 1.5m', 'spacingRow': 1.5, 'spacingPlant': null,
      'seedRate': 'Vipando',
      'fertilizers': {'TSP': 24.7, 'UREA': 115},
      'fertilizerNote': 'P: kilo 24.7, N: kilo 115 kwa hekta',
      'yieldNow': 100.0, 'yieldPotential': 200.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [6000, 6000], 'maturityMonths': [6, 8],
    },
    {
      'jina': 'Pareto', 'jinaEn': 'Pyrethrum',
      'spacing': '0.6m x 0.3m', 'spacingRow': 0.6, 'spacingPlant': 0.3,
      'seedRate': 'Vipande',
      'fertilizers': {'TSP': [100, 200], 'CAN': [250, 500]},
      'yieldNow': 0.75, 'yieldPotential': 1.7, 'yieldUnit': 't/ha',
      'plantsPerHa': [55000, 55000], 'maturityMonths': [4, 4],
    },
    {
      'jina': 'Mkonge', 'jinaEn': 'Sisal',
      'spacing': 'Mstari 3-4m', 'spacingRow': 3.5, 'spacingPlant': null,
      'seedRate': 'Miche',
      'fertilizers': {'CAN': 100, 'TSP': 125},
      'yieldNow': 12.0, 'yieldPotential': 25.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [4700, 4700], 'maturityMonths': [24, 24],
    },
    {
      'jina': 'Mahindi', 'jinaEn': 'Maize',
      'spacing': '0.75m x 0.3m au 0.9m x 0.3m',
      'spacingRow': 0.75, 'spacingPlant': 0.3,
      'seedRate': '25 kg/ha', 'seedRateKgHa': [25, 25],
      'fertilizers': {'DAP': 120, 'TSP': 125, 'UREA': 250},
      'yieldNow': 1.75, 'yieldPotential': 6.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [44450, 50000], 'maturityMonths': [3, 6],
    },
    {
      'jina': 'Mtama', 'jinaEn': 'Sorghum',
      'spacing': '0.8m x 0.3m', 'spacingRow': 0.8, 'spacingPlant': 0.3,
      'seedRate': 'Punje 5 kwa kiganja',
      'fertilizers': {'UREA': [50, 100], 'TSP': [50, 100]},
      'yieldNow': 0.7, 'yieldPotential': 5.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [41200, 111000], 'maturityMonths': [3, 6],
    },
    {
      'jina': 'Mpunga', 'jinaEn': 'Rice',
      'spacing': '0.2m x 0.2m', 'spacingRow': 0.2, 'spacingPlant': 0.2,
      'seedRate': '35-65 kg/ha', 'seedRateKgHa': [35, 65],
      'fertilizers': {'TSP': [150, 300], 'UREA': 175, 'CAN': 300},
      'yieldNow': 2.5, 'yieldPotential': 5.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [82000, 250000], 'maturityMonths': [4, 6],
    },
    {
      'jina': 'Karanga', 'jinaEn': 'Groundnut',
      'spacing': '0.5m x 0.15m', 'spacingRow': 0.5, 'spacingPlant': 0.15,
      'seedRate': '68-90 kg/ha', 'seedRateKgHa': [68, 90],
      'fertilizers': {'TSP': [75, 125]},
      'yieldNow': 0.5, 'yieldPotential': 2.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [133000, 200000], 'maturityMonths': [4, 6],
    },
    {
      'jina': 'Kunde', 'jinaEn': 'Cowpea',
      'spacing': '0.75m x 0.2m', 'spacingRow': 0.75, 'spacingPlant': 0.2,
      'seedRate': '60-75 kg/ha', 'seedRateKgHa': [60, 75],
      'fertilizers': {'TSP': [75, 125], 'NPK': 80},
      'yieldNow': 0.2, 'yieldPotential': 2.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [66667, 66667], 'maturityMonths': [3, 4],
    },
    {
      'jina': 'Maharage', 'jinaEn': 'Beans',
      'spacing': '0.5m x 0.1m', 'spacingRow': 0.5, 'spacingPlant': 0.1,
      'seedRate': '60-70 kg/ha', 'seedRateKgHa': [60, 70],
      'fertilizers': {'TSP': [75, 125], 'NPK': 80},
      'yieldNow': 0.5, 'yieldPotential': 3.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [167000, 200000], 'maturityMonths': [3, 6],
    },
    {
      'jina': 'Alizeti', 'jinaEn': 'Sunflower',
      'spacing': '0.9m x 0.3m', 'spacingRow': 0.9, 'spacingPlant': 0.3,
      'seedRate': '8-12 kg/ha', 'seedRateKgHa': [8, 12],
      'fertilizers': {'TSP': 100, 'CAN': 350},
      'yieldNow': 1.0, 'yieldPotential': 4.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [37000, 44444], 'maturityMonths': [5, 6],
    },
    {
      'jina': 'Ufuta', 'jinaEn': 'Sesame',
      'spacing': '0.6m x 0.1m', 'spacingRow': 0.6, 'spacingPlant': 0.1,
      'seedRate': '3-4 kg/ha', 'seedRateKgHa': [3, 4],
      'fertilizers': {'TSP': [50, 75]},
      'yieldNow': 0.3, 'yieldPotential': 1.2, 'yieldUnit': 't/ha',
      'plantsPerHa': [55556, 166667], 'maturityMonths': [3, 6],
    },
    {
      'jina': 'Uwele', 'jinaEn': 'Pearl Millet',
      'spacing': '0.8m x 0.3m', 'spacingRow': 0.8, 'spacingPlant': 0.3,
      'seedRate': '3-9 kg/ha', 'seedRateKgHa': [3, 9],
      'fertilizers': {'TSP': 65, 'SA': 60},
      'yieldNow': 1.5, 'yieldPotential': 3.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [4000, 100000], 'maturityMonths': [2.5, 4],
    },
    {
      'jina': 'Ulezi', 'jinaEn': 'Finger Millet',
      'spacing': 'Kumwaga / mifereji', 'spacingRow': null, 'spacingPlant': null,
      'seedRate': '20-50 kg/ha', 'seedRateKgHa': [20, 50],
      'fertilizers': {'DAP': [60, 80]},
      'yieldNow': 1.0, 'yieldPotential': 4.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [250000, 400000], 'maturityMonths': [3, 6],
    },
    {
      'jina': 'Ngano', 'jinaEn': 'Wheat',
      'spacing': 'Kumwaga / mifereji', 'spacingRow': null, 'spacingPlant': null,
      'seedRate': '50-200 kg/ha', 'seedRateKgHa': [50, 200],
      'fertilizers': {'TSP': 65, 'SA': 60},
      'yieldNow': 1.5, 'yieldPotential': 5.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [250000, 400000], 'maturityMonths': [3, 6],
    },
    {
      'jina': 'Viazi vitamu', 'jinaEn': 'Sweet Potato',
      'spacing': '0.3m x 1.0m', 'spacingRow': 1.0, 'spacingPlant': 0.3,
      'seedRate': 'Vipando (vines)',
      'fertilizers': {'DAP': [45, 80], 'TSP': [50, 75]},
      'yieldNow': 8.0, 'yieldPotential': 20.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [30000, 35000], 'maturityMonths': [3, 6],
    },
    {
      'jina': 'Viazi mviringo', 'jinaEn': 'Irish Potato',
      'spacing': '0.3m x 0.6m', 'spacingRow': 0.6, 'spacingPlant': 0.3,
      'seedRate': '2000-2500 kg/ha', 'seedRateKgHa': [2000, 2500],
      'fertilizers': {'DAP': [60, 100], 'TSP': [60, 80]},
      'yieldNow': 7.5, 'yieldPotential': 30.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [50000, 56000], 'maturityMonths': [3, 6],
    },
    {
      'jina': 'Ndizi', 'jinaEn': 'Banana',
      'spacing': '3m x 3m', 'spacingRow': 3.0, 'spacingPlant': 3.0,
      'seedRate': 'Machipukizi',
      'fertilizers': {'DAP': [100, 250], 'TSP': [80, 200]},
      'yieldNow': 15.0, 'yieldPotential': 35.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [1111, 1111], 'maturityMonths': [9, 20],
    },
    {
      'jina': 'Muhogo', 'jinaEn': 'Cassava',
      'spacing': '1m x 1m', 'spacingRow': 1.0, 'spacingPlant': 1.0,
      'seedRate': 'Vipando',
      'fertilizers': {'TSP': [35, 40]},
      'yieldNow': 10.0, 'yieldPotential': 60.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [9000, 10000], 'maturityMonths': [6, 24],
    },
    {
      'jina': 'Mbaazi', 'jinaEn': 'Pigeon Pea',
      'spacing': '0.2m x 0.5m', 'spacingRow': 0.5, 'spacingPlant': 0.2,
      'seedRate': '25-50 kg/ha', 'seedRateKgHa': [25, 50],
      'fertilizers': {'TSP': [75, 125], 'NPK': 80, 'DAP': 75},
      'yieldNow': 1.5, 'yieldPotential': 2.5, 'yieldUnit': 't/ha',
      'plantsPerHa': [100000, 100000], 'maturityMonths': [3, 7],
    },
    {
      'jina': 'Soya', 'jinaEn': 'Soybean',
      'spacing': '0.1m x 0.6m', 'spacingRow': 0.6, 'spacingPlant': 0.1,
      'seedRate': '40-100 kg/ha', 'seedRateKgHa': [40, 100],
      'fertilizers': {'NPK': 80, 'DAP': 80},
      'yieldNow': 1.7, 'yieldPotential': 2.7, 'yieldUnit': 't/ha',
      'plantsPerHa': [130000, 167000], 'maturityMonths': [4, 7],
    },
    {
      'jina': 'Dengu', 'jinaEn': 'Lentil/Chickpea',
      'spacing': '0.25m x 0.45m', 'spacingRow': 0.45, 'spacingPlant': 0.25,
      'seedRate': '30-45 kg/ha', 'seedRateKgHa': [30, 45],
      'fertilizers': {'TSP': [45, 60], 'DAP': 50},
      'yieldNow': 0.7, 'yieldPotential': 1.8, 'yieldUnit': 't/ha',
      'plantsPerHa': [80000, 100000], 'maturityMonths': [4, 6],
    },
    {
      'jina': 'Michikichi', 'jinaEn': 'Oil Palm',
      'spacing': '8.8m x 7.6m', 'spacingRow': 8.8, 'spacingPlant': 7.6,
      'seedRate': 'Miche',
      'fertilizers': {},
      'fertilizerNote': 'Mchanganyiko maalum (special mix)',
      'yieldNow': 70.0, 'yieldPotential': 240.0, 'yieldUnit': 'kg/kichane',
      'plantsPerHa': [150, 150], 'maturityMonths': [36, 48],
    },
    {
      'jina': 'Michungwa', 'jinaEn': 'Orange',
      'spacing': '2.5m x 6m', 'spacingRow': 6.0, 'spacingPlant': 2.5,
      'seedRate': 'Miche',
      'fertilizers': {'DAP': 0, 'TSP': 0},
      'fertilizerNote': 'DAP/TSP kulingana na umri wa mti',
      'yieldNow': 20.0, 'yieldPotential': 45.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [667, 667], 'maturityMonths': [36, 48],
    },
    {
      'jina': 'Parachichi', 'jinaEn': 'Avocado',
      'spacing': '8m x 5m', 'spacingRow': 8.0, 'spacingPlant': 5.0,
      'seedRate': 'Miche',
      'fertilizers': {'DAP': 0, 'TSP': 0},
      'fertilizerNote': 'DAP/TSP kulingana na umri wa mti',
      'yieldNow': 1.0, 'yieldPotential': 13.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [250, 250], 'maturityMonths': [48, 60],
    },
    {
      'jina': 'Embe', 'jinaEn': 'Mango',
      'spacing': '10.5m x 10.5m', 'spacingRow': 10.5, 'spacingPlant': 10.5,
      'seedRate': 'Miche',
      'fertilizers': {'DAP': 0, 'TSP': 0},
      'fertilizerNote': 'DAP/TSP kulingana na umri wa mti',
      'yieldNow': 10.0, 'yieldPotential': 25.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [90, 90], 'maturityMonths': [36, 48],
    },
    {
      'jina': 'Papai', 'jinaEn': 'Papaya',
      'spacing': '2.7m x 2.7m', 'spacingRow': 2.7, 'spacingPlant': 2.7,
      'seedRate': 'Miche',
      'fertilizers': {'DAP': 0, 'TSP': 0},
      'fertilizerNote': 'DAP/TSP kulingana na umri wa mti',
      'yieldNow': 100.0, 'yieldPotential': 2500.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [1370, 1370], 'maturityMonths': [9, 16],
    },
    {
      'jina': 'Nanasi', 'jinaEn': 'Pineapple',
      'spacing': '0.6m x 0.6m', 'spacingRow': 0.6, 'spacingPlant': 0.6,
      'seedRate': 'Machipukizi',
      'fertilizers': {'DAP': [80, 100], 'UREA': [80, 100]},
      'yieldNow': 40.0, 'yieldPotential': 55.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [27800, 27800], 'maturityMonths': [12, 16],
    },
    {
      'jina': 'Kabichi', 'jinaEn': 'Cabbage',
      'spacing': '0.75m x 0.6m', 'spacingRow': 0.75, 'spacingPlant': 0.6,
      'seedRate': '0.2-0.3 kg/ha', 'seedRateKgHa': [0.2, 0.3],
      'fertilizers': {'SA': 200},
      'fertilizerNote': 'SA kilo 200/ha — gramu 5 kwa shimo',
      'yieldNow': 20.0, 'yieldPotential': 40.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [22000, 42000], 'maturityMonths': [2.5, 4],
    },
    {
      'jina': 'Nyanya', 'jinaEn': 'Tomato',
      'spacing': '0.75m x 0.5m', 'spacingRow': 0.75, 'spacingPlant': 0.5,
      'seedRate': '0.5 kg/ha', 'seedRateKgHa': [0.5, 0.5],
      'fertilizers': {'DAP': 80, 'CAN': 75},
      'yieldNow': 25.0, 'yieldPotential': 60.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [18000, 26000], 'maturityMonths': [2.5, 4],
    },
    {
      'jina': 'Bilinganya', 'jinaEn': 'Eggplant',
      'spacing': '0.8m x 0.5m', 'spacingRow': 0.8, 'spacingPlant': 0.5,
      'seedRate': '0.5 kg/ha', 'seedRateKgHa': [0.5, 0.5],
      'fertilizers': {'DAP': 75, 'CAN': 80},
      'yieldNow': 20.0, 'yieldPotential': 40.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [12500, 25000], 'maturityMonths': [2.5, 4],
    },
    {
      'jina': 'Vitunguu', 'jinaEn': 'Onion',
      'spacing': '0.1m x 0.3m', 'spacingRow': 0.3, 'spacingPlant': 0.1,
      'seedRate': '4.5 kg/ha', 'seedRateKgHa': [4.5, 4.5],
      'fertilizers': {'DAP': 80, 'CAN': 80, 'UREA': 60},
      'yieldNow': 7.5, 'yieldPotential': 10.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [250000, 333000], 'maturityMonths': [3, 5],
    },
    {
      'jina': 'Bamia', 'jinaEn': 'Okra',
      'spacing': '0.3m x 0.6m', 'spacingRow': 0.6, 'spacingPlant': 0.3,
      'seedRate': '1 kg/ha', 'seedRateKgHa': [1, 1],
      'fertilizers': {'DAP': 75, 'CAN': 80},
      'yieldNow': 1.8, 'yieldPotential': 2.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [56000, 56000], 'maturityMonths': [2, 3],
    },
    {
      'jina': 'Karoti', 'jinaEn': 'Carrot',
      'spacing': 'Kumwaga / mifereji', 'spacingRow': null, 'spacingPlant': null,
      'seedRate': '4.5 kg/ha', 'seedRateKgHa': [4.5, 4.5],
      'fertilizers': {'DAP': 75, 'CAN': 80},
      'yieldNow': 1.5, 'yieldPotential': 15.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [300000, 450000], 'maturityMonths': [2, 3],
    },
    {
      'jina': 'Matango', 'jinaEn': 'Cucumber',
      'spacing': '1.2m x 1.5m', 'spacingRow': 1.5, 'spacingPlant': 1.2,
      'seedRate': '2.5 kg/ha', 'seedRateKgHa': [2.5, 2.5],
      'fertilizers': {'NPK': [100, 200]},
      'fertilizerNote': 'NPK (4:16:4) kilo 100-200 kwa hekta',
      'yieldNow': 4.0, 'yieldPotential': 8.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [4000, 5000], 'maturityMonths': [2, 3],
    },
    {
      'jina': 'Tikiti maji', 'jinaEn': 'Watermelon',
      'spacing': '1.2m x 1.5m', 'spacingRow': 1.5, 'spacingPlant': 1.2,
      'seedRate': '2.5 kg/ha', 'seedRateKgHa': [2.5, 2.5],
      'fertilizers': {'NPK': [100, 200]},
      'fertilizerNote': 'NPK (4:16:4) kilo 100-200 kwa hekta',
      'yieldNow': 9.0, 'yieldPotential': 12.0, 'yieldUnit': 't/ha',
      'plantsPerHa': [4000, 5000], 'maturityMonths': [3, 4],
    },
  ];

  // Find crop entry by Swahili name (case-insensitive)
  static Map<String, dynamic>? findCrop(String name) {
    final n = name.toLowerCase().trim();
    for (final c in crops) {
      if ((c['jina'] as String).toLowerCase() == n) return c;
    }
    // Partial match fallback
    for (final c in crops) {
      if ((c['jina'] as String).toLowerCase().contains(n) ||
          n.contains((c['jina'] as String).toLowerCase())) {
        return c;
      }
    }
    return null;
  }

  // List of all crop names (Swahili)
  static List<String> get cropNames =>
      crops.map((c) => c['jina'] as String).toList();

  // Mean value of a fertilizer amount (num or [min, max] range)
  static double fertilizerAmount(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is List && v.length == 2) {
      return ((v[0] as num) + (v[1] as num)) / 2.0;
    }
    return 0;
  }
}
