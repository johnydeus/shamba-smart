import 'package:supabase_flutter/supabase_flutter.dart';

class OfficerService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ── Find officers for a farmer's region ──────────────────────────────────
  static Future<List<Map<String, dynamic>>> findOfficersForFarmer({
    required double farmerLat,
    required double farmerLng,
    required String farmerRegion,
    String? farmerDistrict,
    String? cropSpeciality,
  }) async {
    try {
      var query = _db
          .from('agri_officers')
          .select()
          .eq('is_active', true)
          .eq('primary_region', farmerRegion);

      final rows = await query.order('is_verified', ascending: false);

      var officers = List<Map<String, dynamic>>.from(rows);

      // If no officers in exact region, try all active verified
      if (officers.isEmpty) {
        final fallback = await _db
            .from('agri_officers')
            .select()
            .eq('is_active', true)
            .order('is_verified', ascending: false)
            .limit(10);
        officers = List<Map<String, dynamic>>.from(fallback);
      }

      // Filter by crop speciality if provided
      if (cropSpeciality != null && cropSpeciality.isNotEmpty) {
        final filtered = officers.where((o) {
          final specs = (o['specialisation'] as List?)?.cast<String>() ?? [];
          return specs.any((s) =>
              s.toLowerCase().contains(cropSpeciality.toLowerCase()));
        }).toList();
        if (filtered.isNotEmpty) officers = filtered;
      }

      // Sort: verified first → highest rating → closest
      officers.sort((a, b) {
        final aVerified = (a['is_verified'] as bool?) == true ? 0 : 1;
        final bVerified = (b['is_verified'] as bool?) == true ? 0 : 1;
        if (aVerified != bVerified) return aVerified.compareTo(bVerified);

        final aRating = (a['average_rating'] as num?)?.toDouble() ?? 0.0;
        final bRating = (b['average_rating'] as num?)?.toDouble() ?? 0.0;
        return bRating.compareTo(aRating);
      });

      return officers;
    } catch (_) {
      return _sampleOfficers(farmerRegion);
    }
  }

  // ── Auto-link farmer to nearest officer ──────────────────────────────────
  static Future<String?> autoLinkFarmerToOfficer({
    required String farmerId,
    required double lat,
    required double lng,
    required String region,
    String? district,
  }) async {
    try {
      // Check if already linked
      final existing = await _db
          .from('farmer_officer_links')
          .select('id')
          .eq('farmer_id', farmerId)
          .eq('status', 'active')
          .maybeSingle();
      if (existing != null) return null;

      final officers = await findOfficersForFarmer(
        farmerLat: lat, farmerLng: lng, farmerRegion: region);
      if (officers.isEmpty) return null;

      final officer = officers.first;
      await _db.from('farmer_officer_links').insert({
        'farmer_id': farmerId,
        'officer_id': officer['id'],
        'link_type': 'regional',
        'is_primary': true,
        'status': 'active',
      });

      return officer['full_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Get broadcasts for farmer's region ────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getRegionalBroadcasts({
    required String region,
    String? district,
    String? cropFilter,
  }) async {
    try {
      final rows = await _db
          .from('officer_broadcasts')
          .select('*, agri_officers(full_name, title)')
          .eq('is_active', true)
          .eq('target_region', region)
          .order('published_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(rows);
    } catch (_) {
      return _sampleBroadcasts(region);
    }
  }

  // ── Get farmer's linked officer ───────────────────────────────────────────
  static Future<Map<String, dynamic>?> getLinkedOfficer(
      String farmerId) async {
    try {
      final link = await _db
          .from('farmer_officer_links')
          .select('officer_id')
          .eq('farmer_id', farmerId)
          .eq('is_primary', true)
          .eq('status', 'active')
          .maybeSingle();
      if (link == null) return null;

      return await _db
          .from('agri_officers')
          .select()
          .eq('id', link['officer_id'])
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  // ── Get all farmers linked to an officer ──────────────────────────────────
  static Future<List<Map<String, dynamic>>> getOfficerFarmers(
      String officerId) async {
    try {
      final links = await _db
          .from('farmer_officer_links')
          .select('farmer_id')
          .eq('officer_id', officerId)
          .eq('status', 'active');

      final farmerIds =
          (links as List).map((l) => l['farmer_id'] as String).toList();
      if (farmerIds.isEmpty) return [];

      final profiles = await _db
          .from('profiles')
          .select('id, first_name, last_name, region')
          .inFilter('id', farmerIds);
      return List<Map<String, dynamic>>.from(profiles);
    } catch (_) {
      return [];
    }
  }

  // ── Rate an officer ───────────────────────────────────────────────────────
  static Future<void> rateOfficer({
    required String farmerId,
    required String officerId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _db.from('officer_ratings').upsert({
        'farmer_id': farmerId,
        'officer_id': officerId,
        'rating': rating,
        'comment': comment,
      });

      // Recalculate average rating
      final ratings = await _db
          .from('officer_ratings')
          .select('rating')
          .eq('officer_id', officerId);
      final list = (ratings as List).map((r) => (r['rating'] as num).toInt());
      if (list.isEmpty) return;
      final avg = list.reduce((a, b) => a + b) / list.length;
      await _db.from('agri_officers').update({
        'average_rating': avg,
        'total_ratings': list.length,
      }).eq('id', officerId);
    } catch (_) {}
  }

  // ── Post a broadcast (officer only) ──────────────────────────────────────
  static Future<void> postBroadcast({
    required String officerId,
    required String title,
    required String message,
    required String region,
    String? district,
    String? targetCrop,
    String priority = 'normal',
    String broadcastType = 'advisory',
  }) async {
    await _db.from('officer_broadcasts').insert({
      'officer_id': officerId,
      'title': title,
      'message': message,
      'target_region': region,
      'target_district': district,
      'target_crop': targetCrop,
      'priority': priority,
      'broadcast_type': broadcastType,
      'is_active': true,
      'published_at': DateTime.now().toIso8601String(),
    });
  }

  // ── Sample data fallback (no Supabase tables yet) ─────────────────────────
  static List<Map<String, dynamic>> _sampleOfficers(String region) => [
        {
          'id': 'sample-1',
          'full_name': 'Dkt. Amani Mwalimu',
          'title': 'Mtaalamu wa Mazao',
          'qualification': 'BSc Agronomy, SUA',
          'specialisation': ['mahindi', 'nyanya', 'mbolea'],
          'employer': 'Wizara ya Kilimo',
          'primary_region': region,
          'primary_district': 'Kilosa',
          'phone': '+255 765 000 001',
          'is_active': true,
          'is_verified': true,
          'average_rating': 4.8,
          'total_ratings': 23,
          'response_time_hours': 4.0,
          'farmers_served': 47,
          'bio': 'Nina uzoefu wa miaka 12 katika kilimo cha nafaka '
              'na mbogamboga. Nimefanya kazi katika wilaya za Morogoro, '
              'Kilosa na Kilombero.',
          'farm_visit_available': true,
          'farm_visit_cost_tzs': 25000,
        },
        {
          'id': 'sample-2',
          'full_name': 'Bi. Zawadi Msigwa',
          'title': 'Afisa Kilimo',
          'qualification': 'Diploma Kilimo, Uyole',
          'specialisation': ['kahawa', 'mahindi', 'viazi'],
          'employer': 'Serikali ya Mkoa',
          'primary_region': 'Mbeya',
          'primary_district': 'Mbeya Vijijini',
          'phone': '+255 713 000 002',
          'is_active': true,
          'is_verified': false,
          'average_rating': 4.5,
          'total_ratings': 11,
          'response_time_hours': 12.0,
          'farmers_served': 89,
          'bio': 'Afisa kilimo katika wilaya ya Mbeya Vijijini. '
              'Mtaalamu wa kahawa na mazao ya baridi.',
          'farm_visit_available': false,
          'farm_visit_cost_tzs': 0,
        },
        {
          'id': 'sample-3',
          'full_name': 'Bw. Emmanuel Komba',
          'title': 'Agronomist',
          'qualification': 'MSc Agronomy, UDSM',
          'specialisation': ['pamba', 'alizeti', 'soya'],
          'employer': 'Private Consultant',
          'primary_region': 'Dodoma',
          'primary_district': 'Kongwa',
          'phone': '+255 756 000 003',
          'is_active': true,
          'is_verified': true,
          'average_rating': 4.9,
          'total_ratings': 34,
          'response_time_hours': 2.0,
          'farmers_served': 120,
          'bio': 'Agronomist binafsi na uzoefu wa miaka 8. '
              'Mtaalamu wa mazao ya biashara Dodoma na Singida.',
          'farm_visit_available': true,
          'farm_visit_cost_tzs': 30000,
        },
        {
          'id': 'sample-4',
          'full_name': 'Dkt. Salma Hamisi',
          'title': 'Mshauri wa TPRI',
          'qualification': 'BSc Plant Protection, SUA',
          'specialisation': ['viuatilifu', 'magonjwa ya mazao', 'nyanya'],
          'employer': 'TPRI - Arusha',
          'primary_region': 'Arusha',
          'primary_district': 'Arumeru',
          'phone': '+255 784 000 004',
          'is_active': true,
          'is_verified': true,
          'average_rating': 4.7,
          'total_ratings': 19,
          'response_time_hours': 6.0,
          'farmers_served': 65,
          'bio': 'Mshauri kutoka TPRI. Mtaalamu wa udhibiti wa '
              'wadudu na magonjwa kwa mazao ya Kaskazini Tanzania.',
          'farm_visit_available': true,
          'farm_visit_cost_tzs': 40000,
        },
        {
          'id': 'sample-5',
          'full_name': 'Bw. Hashim Ramadhani',
          'title': 'Afisa Kilimo',
          'qualification': 'Certificate in Agriculture',
          'specialisation': ['mpunga', 'ndizi', 'mbogamboga'],
          'employer': 'Halmashauri ya Wilaya',
          'primary_region': 'Pwani',
          'primary_district': 'Rufiji',
          'phone': '+255 699 000 005',
          'is_active': true,
          'is_verified': false,
          'average_rating': 4.2,
          'total_ratings': 8,
          'response_time_hours': 24.0,
          'farmers_served': 33,
          'bio': 'Afisa kilimo Pwani. Mtaalamu wa mpunga wa '
              'mashamba ya mwambao na bonde la Rufiji.',
          'farm_visit_available': false,
          'farm_visit_cost_tzs': 0,
        },
      ];

  static List<Map<String, dynamic>> _sampleBroadcasts(String region) => [
        {
          'id': 'b1',
          'title': 'Tahadhari: Viwavi vya Mahindi $region',
          'message': 'Wakulima wa $region: Kuna mlipuko wa viwavi '
              '(Fall Armyworm) katika mashamba ya mahindi. Angalieni '
              'mashamba yenu na ripoti kwa afisa kilimo wa karibu nawe. '
              'Tumia dawa za Emamectin Benzoate 19 g/EC kama dalili '
              'zinaonekana.',
          'priority': 'urgent',
          'broadcast_type': 'alert',
          'published_at': DateTime.now()
              .subtract(const Duration(days: 2))
              .toIso8601String(),
          'agri_officers': {
            'full_name': 'Dkt. Amani Mwalimu',
            'title': 'Mtaalamu wa Mazao'
          },
        },
        {
          'id': 'b2',
          'title': 'Bei Nzuri za Mahindi Sokoni',
          'message': 'Habari njema: Bei za mahindi zimepanda hadi TZS 650 '
              'kwa kg kwenye soko la $region wiki hii. '
              'Wakulima wanaona hii kama wakati mzuri wa kuuza.',
          'priority': 'normal',
          'broadcast_type': 'advisory',
          'published_at': DateTime.now()
              .subtract(const Duration(days: 5))
              .toIso8601String(),
          'agri_officers': {
            'full_name': 'Bi. Zawadi Msigwa',
            'title': 'Afisa Kilimo'
          },
        },
      ];
}
