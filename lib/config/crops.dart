/// Canonical Tanzanian crop list — the SINGLE source of truth for the scan
/// picker, the live-scan picker, and farm registration. Keep additions here
/// only. (Source: Ministry of Agriculture, TAHA, TOSCI, TanzaniaInvest.)
const List<String> kCrops = [
  // Nafaka (Cereals)
  'Mahindi', 'Mchele', 'Ngano', 'Mtama', 'Uwele', 'Ulezi', 'Shayiri',
  // Mikunde (Legumes)
  'Maharagwe', 'Choroko', 'Karanga', 'Soya', 'Mbaazi', 'Kunde',
  // Mbogamboga (Vegetables)
  'Nyanya', 'Kabichi', 'Sukuma wiki', 'Vitunguu', 'Pilipili hoho',
  'Pilipili manga', 'Karoti', 'Bamia', 'Tango', 'Bilinganya',
  'Mchicha', 'Tikiti maji', 'Njegere', 'Maharage ya Kata',
  // Mazao ya Mizizi (Root crops)
  'Muhogo', 'Viazi vitamu', 'Viazi',
  // Matunda (Fruits)
  'Ndizi', 'Embe', 'Papai', 'Nanasi', 'Avokado', 'Marakuja',
  'Chungwa', 'Zabibu', 'Stroberri', 'Nazi',
  // Mazao ya Biashara (Cash crops)
  'Pamba', 'Alizeti', 'Kahawa', 'Chai', 'Korosho', 'Miwa',
  'Katani', 'Tumbaku', 'Karafuu', 'Ufuta', 'Pareto',
  // Viungo (Spices)
  'Tangawizi', 'Iliki',
];

/// Emoji per crop for chip display; falls back to a generic seedling.
const Map<String, String> kCropEmojis = {
  'Mahindi': '🌽',
  'Mchele': '🍚',
  'Nyanya': '🍅',
  'Maharagwe': '🫘',
  'Ndizi': '🍌',
  'Muhogo': '🥔',
  'Pamba': '☁️',
  'Kahawa': '☕',
  'Nazi': '🥥',
  'Tangawizi': '🫚',
  'Ufuta': '🌱',
  'Pareto': '🌼',
  'Iliki': '🌿',
};

String cropEmoji(String crop) => kCropEmojis[crop] ?? '🌱';
