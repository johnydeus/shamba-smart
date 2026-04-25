import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';

const _kListings = 'ss_listings';

class ListingProvider extends ChangeNotifier {
  List<ListingModel> _listings = [];
  String _searchQuery = '';
  ListingType? _categoryFilter; // null = show all

  List<ListingModel> get allListings => _listings;
  ListingType? get categoryFilter => _categoryFilter;

  // Filtered + searched listings shown in UI
  List<ListingModel> get filteredListings {
    var list = _listings;
    if (_categoryFilter != null) {
      list = list.where((l) => l.type == _categoryFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((l) {
        return l.title.toLowerCase().contains(q) ||
            l.location.toLowerCase().contains(q) ||
            l.description.toLowerCase().contains(q) ||
            l.seller.name.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  // Load listings from SharedPreferences; seeds demo data if empty
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kListings);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _listings = list
          .map((e) => ListingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // Seed demo listings on first launch
    if (_listings.isEmpty) {
      _listings = _seedListings();
      await _save();
    }
    notifyListeners();
  }

  // Add a new listing at the top of the list
  Future<void> addListing(ListingModel listing) async {
    _listings.insert(0, listing);
    await _save();
    notifyListeners();
  }

  // Delete a listing by id
  Future<void> deleteListing(String id) async {
    _listings.removeWhere((l) => l.id == id);
    await _save();
    notifyListeners();
  }

  // Set category filter (null = all)
  void filterByCategory(ListingType? type) {
    _categoryFilter = type;
    notifyListeners();
  }

  // Update search query
  void searchListings(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(_listings.map((l) => l.toJson()).toList());
    await prefs.setString(_kListings, encoded);
  }

  // ── Demo seed data (8 listings) ───────────────────────────────────────────
  List<ListingModel> _seedListings() => [
        ListingModel(
          id: '1000001',
          type: ListingType.mazao,
          emoji: '🌶️',
          title: 'Pilipili Kali Kavu Daraja A',
          description:
              'Pilipili kali kavu ya hali ya juu, ilimwa bila dawa za sumu. '
              'Inafaa kwa soko la ndani na nje ya nchi. '
              'Kaunta inayoonekana vizuri na harufu nzuri.',
          price: 3200,
          unit: 'kg',
          quantityAvailable: 500,
          location: 'Chalinze, Pwani',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          seller: const SellerInfo(
            id: 'seller_001',
            name: 'Amina Rashid',
            role: UserRole.mkulima,
            colorHex: '#2E7D32',
          ),
          badgeText: 'Mpya',
          badgeColorHex: '#2E7D32',
        ),
        ListingModel(
          id: '1000002',
          type: ListingType.dawa,
          emoji: '💊',
          title: 'Dawa ya Aphid — Imidacloprid 200ml',
          description:
              'Dawa ya kuua aphid na whitefly. Imeidhinishwa na TPRI Tanzania. '
              'Inafaa kwa nyanya, pilipili, vitunguu na maharagwe. '
              'Kipimo: 10ml kwa dumu la 15L.',
          price: 8500,
          unit: 'chupa',
          quantityAvailable: 50,
          location: 'Morogoro Mjini',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          seller: const SellerInfo(
            id: 'seller_002',
            name: 'AgriPlus Morogoro',
            role: UserRole.duka,
            colorHex: '#1565C0',
          ),
          badgeText: 'TPRI ✓',
          badgeColorHex: '#1565C0',
        ),
        ListingModel(
          id: '1000003',
          type: ListingType.mbegu,
          emoji: '🌱',
          title: 'Mbegu za Nyanya F1 Hybrid 50g',
          description:
              'Mbegu za nyanya mseto zinazostahimili ugonjwa wa TYLCV. '
              'Tija: tani 55-60 kwa hekta. Zinafaa kwa umwagiliaji. '
              'Imeidhinishwa na TOSCI Tanzania.',
          price: 12000,
          unit: 'pakiti',
          quantityAvailable: 200,
          location: 'Arusha',
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
          seller: const SellerInfo(
            id: 'seller_003',
            name: 'SeedPro Tanzania',
            role: UserRole.duka,
            colorHex: '#1565C0',
          ),
          badgeText: 'TOSCI ✓',
          badgeColorHex: '#0277BD',
        ),
        ListingModel(
          id: '1000004',
          type: ListingType.shamba,
          emoji: '🏡',
          title: 'Shamba Ekari 10 — Chalinze',
          description:
              'Shamba zuri la tambarare na udongo wa tifutifu. '
              'Lina bomba la maji karibu. Linafaa kwa nyanya, '
              'vitunguu, na maharagwe. Karibu na barabara kuu.',
          price: 180000,
          unit: 'mwezi',
          quantityAvailable: 1,
          location: 'Chalinze, Pwani',
          createdAt:
              DateTime.now().subtract(const Duration(days: 1)),
          seller: const SellerInfo(
            id: 'seller_004',
            name: 'Musa Komba',
            role: UserRole.mwekezaji,
            colorHex: '#C8860A',
          ),
          badgeText: 'Inapatikana',
          badgeColorHex: '#C8860A',
        ),
        ListingModel(
          id: '1000005',
          type: ListingType.mazao,
          emoji: '🧅',
          title: 'Vitunguu Maji — Ikungi, Singida',
          description:
              'Vitunguu vikubwa vya ubora wa juu kutoka Ikungi. '
              'Vimekaguliwa na havina ugonjwa. '
              'Vinaweza kusafirishwa nchi nzima. Bei inaweza kujadiliwa.',
          price: 1800,
          unit: 'kg',
          quantityAvailable: 3000,
          location: 'Ikungi, Singida',
          createdAt:
              DateTime.now().subtract(const Duration(days: 1)),
          seller: const SellerInfo(
            id: 'seller_005',
            name: 'Hassan Ikungi Farm',
            role: UserRole.mkulima,
            colorHex: '#2E7D32',
          ),
          badgeText: 'Tani 3 Zinapatikana',
          badgeColorHex: '#2E7D32',
        ),
        ListingModel(
          id: '1000006',
          type: ListingType.zana,
          emoji: '⚙️',
          title: 'Pump ya Maji Honda 3" WB30',
          description:
              'Pampu ya maji ya Honda yenye nguvu ya 3 inchi. '
              'Inaweza kupandisha maji mita 30 juu. '
              'Hali nzuri, imetumika msimu 1 tu. Inakuja na hose 20m.',
          price: 450000,
          unit: 'kipande',
          quantityAvailable: 1,
          location: 'Dar es Salaam',
          createdAt:
              DateTime.now().subtract(const Duration(days: 2)),
          seller: const SellerInfo(
            id: 'seller_006',
            name: 'AgroTech DSM',
            role: UserRole.duka,
            colorHex: '#1565C0',
          ),
          badgeText: 'Hali Nzuri',
          badgeColorHex: '#1565C0',
        ),
        ListingModel(
          id: '1000007',
          type: ListingType.usafiri,
          emoji: '🚛',
          title: 'Lori 5t — DSM ↔ Morogoro',
          description:
              'Usafiri wa mazao kwa lori lenye uwezo wa tani 5. '
              'Safari mbili kwa wiki: Ijumaa na Jumatatu. '
              'Tunaweza kuchukua mizigo yako kutoka shambani.',
          price: 120000,
          unit: 'safari',
          quantityAvailable: 10,
          location: 'Dar es Salaam',
          createdAt:
              DateTime.now().subtract(const Duration(days: 2)),
          seller: const SellerInfo(
            id: 'seller_007',
            name: 'Mbogamboga Logistics',
            role: UserRole.muuzaji,
            colorHex: '#6A1B9A',
          ),
          badgeText: 'Kila Wiki',
          badgeColorHex: '#6A1B9A',
        ),
        ListingModel(
          id: '1000008',
          type: ListingType.dawa,
          emoji: '🌿',
          title: 'Mbolea DAP 50kg',
          description:
              'Mbolea ya DAP (Diammonium Phosphate) gunia la kilo 50. '
              'Inafaa kupanda mahindi, nyanya, na mazao mengine. '
              'Inapatikana na bei ya jumla kwa minunuzi wa gunia 10+.',
          price: 95000,
          unit: 'gunia',
          quantityAvailable: 100,
          location: 'Morogoro Mjini',
          createdAt:
              DateTime.now().subtract(const Duration(days: 3)),
          seller: const SellerInfo(
            id: 'seller_002',
            name: 'AgriPlus Morogoro',
            role: UserRole.duka,
            colorHex: '#1565C0',
          ),
          badgeText: 'Bei ya Jumla',
          badgeColorHex: '#C8860A',
        ),
      ];
}
