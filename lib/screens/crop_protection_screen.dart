import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/claude_service.dart';
import '../theme/app_colors.dart';
import 'scan_screen.dart';
import 'results_screen.dart';

// ── Offline threat database (Tanzania-specific) ───────────────────────────────

class _Threat {
  final String emoji;
  final String nameSw;
  final String nameEn;
  final String symptoms;
  final String immediateAction;
  final String dawa1;
  final String dawa1Dose;
  final String dawa2;
  final String dawa2Dose;
  final String prevention;
  final bool isEmergency;

  const _Threat({
    required this.emoji,
    required this.nameSw,
    required this.nameEn,
    required this.symptoms,
    required this.immediateAction,
    required this.dawa1,
    required this.dawa1Dose,
    this.dawa2 = '',
    this.dawa2Dose = '',
    required this.prevention,
    this.isEmergency = false,
  });
}

const _waduduThreats = <_Threat>[
  _Threat(
    emoji: '🪲',
    nameSw: 'Viwavi wa Jeshi',
    nameEn: 'Fall Armyworm (Spodoptera frugiperda)',
    symptoms:
        'Majani ya mahindi yana matundu makubwa. Kinyesi chekundu kwenye mmea. '
        'Viwavi wenye rangi ya kahawia/kijani kwenye ndani ya mmea.',
    immediateAction:
        'Angalia mashamba asubuhi na jioni. Kata na haribu mimea yenye viwavi. '
        'Piga dawa siku 1–2 za kwanza kuona dalili.',
    dawa1: 'Coragen 20SC (Chlorantraniliprole)',
    dawa1Dose: '3ml kwa dumu la lita 15',
    dawa2: 'Dipel WP (Bacillus thuringiensis)',
    dawa2Dose: '15g kwa dumu la lita 15 (dawa ya asili)',
    prevention:
        'Panda mapema (Novemba). Tumia mbegu sugu. Zuia magugu. '
        'Angalia mashamba kila wiki kuanzia wiki 3 baada ya kupanda.',
    isEmergency: true,
  ),
  _Threat(
    emoji: '🦗',
    nameSw: 'Nzige wa Jangwani',
    nameEn: 'Desert Locust (Schistocerca gregaria)',
    symptoms:
        'Makundi makubwa ya wadudu wenye mabawa yanayoruka pamoja. '
        'Mazao kuliwa haraka kama dakika 30. Sauti ya nguruwe angani.',
    immediateAction:
        'PIGA SIMU HARAKA: Idara ya Kilimo Wilayani (0800110104). '
        'Pigakelele (tahadhari jamii). Usijaribu kupiga dawa peke yako.',
    dawa1: 'Chlorpyrifos (dawa ya serikali)',
    dawa1Dose: 'Kupigwa na helikopta/ndege tu — usiagize peke yako',
    prevention:
        'Fuatilia arifa za FAO/DLCO-EA kwenye redio. '
        'Hifadhi mazao yaliyovunwa haraka. Jua njia ya kuwasiliana na ofisi ya kilimo.',
    isEmergency: true,
  ),
  _Threat(
    emoji: '🪰',
    nameSw: 'Inzi Weupe',
    nameEn: 'Whitefly (Bemisia tabaci)',
    symptoms:
        'Viumbe vidogo vyeupe vinaruka ukigusa mmea. '
        'Majani yanageuka njano. Utomvu wa asali kwenye majani (sooty mould).',
    immediateAction:
        'Ondoa majani yenye mayai. Tumia mtego wa njano wenye mseto wa mafuta.',
    dawa1: 'Confidor (Imidacloprid) 200SL',
    dawa1Dose: '5ml kwa dumu la lita 15',
    dawa2: 'Sabuni ya kuosha (organic)',
    dawa2Dose: 'Kijiko 2 kwa dumu la lita 15',
    prevention:
        'Weka neti za kuzuia wadudu kwenye bustani. Ondoa mimea ya karibu yenye maambukizo. '
        'Tumia mbegu sugu ya TOSCI.',
  ),
  _Threat(
    emoji: '🦟',
    nameSw: 'Vidukari / Aphids',
    nameEn: 'Aphids (Aphis spp.)',
    symptoms:
        'Wadudu wadogo wenye rangi kijani/nyeusi wamekusanyika kwenye shina la jani. '
        'Majani yamekunjamana. Mmea umedumaa ukuaji.',
    immediateAction:
        'Osha mimea kwa maji ya nguvu. Vuna wadudu kwa mkono (kwa bustani ndogo).',
    dawa1: 'Actara 25WG (Thiamethoxam)',
    dawa1Dose: '2g kwa dumu la lita 15',
    dawa2: 'Neem oil (mafuta ya mwarobaini)',
    dawa2Dose: '20ml kwa dumu la lita 15',
    prevention:
        'Zuia mchwa — wanabeba vidukari. Vunja mzunguko wa mimea. '
        'Panda marigold (tagetes) karibu na mazao.',
  ),
  _Threat(
    emoji: '🕷️',
    nameSw: 'Utitiri wa Buibui',
    nameEn: 'Spider Mite (Tetranychus urticae)',
    symptoms:
        'Matone madogo ya njano/nyekundu kwenye majani. '
        'Utando mwembamba chini ya jani. Majani hukauka.',
    immediateAction:
        'Ongeza unyevu (punyiza maji kwenye majani mara mbili kwa siku).',
    dawa1: 'Envidor 240SC (Spirodiclofen)',
    dawa1Dose: '4ml kwa dumu la lita 15',
    prevention:
        'Epuka kusinyaa kwa mmea. Inzi wawindaji (Phytoseiidae) wanasaidia asili. '
        'Usitumie dawa za OP nyingi — zinamaliza wadudu wawindaji.',
  ),
];

const _magonjwaThreats = <_Threat>[
  _Threat(
    emoji: '🍄',
    nameSw: 'Kutu ya Mahindi',
    nameEn: 'Maize Rust (Puccinia polysora)',
    symptoms:
        'Vipele vidogo vya rangi ya machungwa/kahawia juu ya majani. '
        'Unga mwembamba ukiweza kupigwa na kidole. Majani hugeuka njano.',
    immediateAction:
        'Kata na choma majani yaliyoathirika. Usibebe viumbe kwenye mashamba mengine.',
    dawa1: 'Tilt 250EC (Propiconazole)',
    dawa1Dose: '10ml kwa dumu la lita 15',
    dawa2: 'Dithane M-45 (Mancozeb)',
    dawa2Dose: '25g kwa dumu la lita 15',
    prevention:
        'Tumia mahindi bora ya mseto (DK8031, SEEDCO SC403). '
        'Zuia umwagiliaji wa juu (inasambaza spores). Zuia mazao ya jirani.',
  ),
  _Threat(
    emoji: '🫛',
    nameSw: 'Ugonjwa wa Majani ya Nyanya',
    nameEn: 'Tomato Early Blight (Alternaria solani)',
    symptoms:
        'Madoa ya kahawia yenye mzunguko wa pete (target spots). '
        'Madoa huanza majani ya chini halafu yanainuka. '
        'Mmea unaweza kupoteza majani yote.',
    immediateAction:
        'Ondoa na choma majani yote yaliyoathirika. Piga dawa mara moja.',
    dawa1: 'Ridomil Gold MZ 68WP (Mancozeb + Metalaxyl)',
    dawa1Dose: '25g kwa dumu la lita 15',
    dawa2: 'Score 250EC (Difenoconazole)',
    dawa2Dose: '5ml kwa dumu la lita 15',
    prevention:
        'Mwagilia kwenye ardhi tu (si juu ya mmea). Acha nafasi kati ya mimea. '
        'Vunja mzunguko wa mazao — usipande nyanya mahali pamoja kila mwaka.',
  ),
  _Threat(
    emoji: '🌿',
    nameSw: 'Ugonjwa wa Mosaic ya Muhogo',
    nameEn: 'Cassava Mosaic Disease (CMD)',
    symptoms:
        'Majani yangeuka njano na kijani kwa mifumo ya kawaida (mosaic pattern). '
        'Majani yamekunjamana au yamekuwa ndogo. Mmea umedumaa.',
    immediateAction:
        'HAKUNA TIBA. Ng\'oa na choma mimea yote yenye dalili mara moja. '
        'Usieneze vipande vya muhogo wenye maambukizo.',
    dawa1: 'Confidor (Imidacloprid) — dhidi ya inzi weupe wanaoeneza CMD',
    dawa1Dose: '5ml kwa dumu la lita 15',
    prevention:
        'Tumia tu vipande vya muhogo kutoka vyanzo safi (IITA/CIAT). '
        'Panda aina sugu: Kiroba, Mkuranga, Seme.',
    isEmergency: true,
  ),
  _Threat(
    emoji: '🫑',
    nameSw: 'Blight ya Viazi Vitamu',
    nameEn: 'Sweet Potato Scab (Elsinoe batatas)',
    symptoms:
        'Madoa ya kijivu/kahawia yenye mpaka mweusi kwenye majani. '
        'Vidonda kwenye shina. Viazi vina makovu.',
    immediateAction:
        'Tumia mbegu safi. Anza kupiga dawa wiki 3 baada ya kupanda.',
    dawa1: 'Copper Oxychloride 50WP',
    dawa1Dose: '30g kwa dumu la lita 15',
    prevention:
        'Tumia mbegu za TOSCI zilizoidhinishwa. Punguza unyevu kupita kiasi.',
  ),
  _Threat(
    emoji: '🌾',
    nameSw: 'Mnyauko wa Mchele (Blast)',
    nameEn: 'Rice Blast (Magnaporthe oryzae)',
    symptoms:
        'Madoa ya alama ya jicho (eye-shaped lesions) kwenye majani — kati ni kijivu, nje ni kahawia. '
        'Mashikio ya mchele yanageuka nyekundu/nyeusi na kufa kabla ya kuvuna.',
    immediateAction:
        'Piga dawa mara dalili zinaonekana. Hakikisha umwagiliaji unatosha.',
    dawa1: 'Beam 75WP (Tricyclazole)',
    dawa1Dose: '12g kwa dumu la lita 15',
    dawa2: 'Hinosan 50EC (Edifenphos)',
    dawa2Dose: '15ml kwa dumu la lita 15',
    prevention:
        'Usipande mchele mingi kwenye eneo moja. Tumia mbegu bora: Supa India, NERICA. '
        'Zungusha mazao.',
  ),
];

const _maguguThreats = <_Threat>[
  _Threat(
    emoji: '🌱',
    nameSw: 'Striga (Mgalagala)',
    nameEn: 'Striga / Witchweed (Striga hermonthica)',
    symptoms:
        'Mimea midogo yenye maua ya zambarau/nyekundu inayochomoza kwenye ardhi karibu na mahindi. '
        'Mahindi yanaonekana kudumaa au kufa mstari mzima.',
    immediateAction:
        'Yavune kabla ya kutoa mbegu (kabla ya maua). USIYAACHA ardhini. '
        'Yakausha juani na uchome au yafunge kwenye mfuko na utupe mbali.',
    dawa1: 'Imazapyr (Imazapyr-IR) — kwa mbegu zilizotiwa dawa',
    dawa1Dose: 'Mbegu hutayarishwa kabla ya kupanda — wasiliana na TPRI',
    dawa2: 'Glyphosate 360SL (kwa njia ndogo tu)',
    dawa2Dose: '20ml kwa dumu la lita 15 — usipige kwenye mazao',
    prevention:
        'Tumia mbegu za mahindi zilizochanganywa na Imazapyr (Push-Pull tech). '
        'Panda Desmodium (silverleaf) kati ya mistari — inazuia Striga asili. '
        'Zungusha na mikunde (maharagwe, soya).',
    isEmergency: true,
  ),
  _Threat(
    emoji: '🌿',
    nameSw: 'Nyasi Tenge (Mzuzu)',
    nameEn: 'Couch Grass / Bermuda Grass (Cynodon dactylon)',
    symptoms:
        'Nyasi inayoenea haraka na mizizi mirefu chini. '
        'Inagombana na mazao kwa maji na virutubisho.',
    immediateAction:
        'Lima kina kirefu na ondoa mizizi yote. Kawaida lazima ufanye mara 3–4.',
    dawa1: 'Fusilade Super 125EC (Fluazifop-P-butyl)',
    dawa1Dose: '15ml kwa dumu la lita 15 — kwa mazao mapana (si nyanya)',
    prevention: 'Mulch mzuri unasaidia. Lima mapema kabla ya kupanda.',
  ),
  _Threat(
    emoji: '🌾',
    nameSw: 'Blackjack (Mgumba)',
    nameEn: 'Black Jack (Bidens pilosa)',
    symptoms: 'Mmea wenye maua meupe na mbegu nyeusi zinazoshikamana nguo.',
    immediateAction: 'Ng\'oa kabla ya kutoa mbegu.',
    dawa1: '2,4-D Amine 720SL',
    dawa1Dose: '15ml kwa dumu la lita 15 — kwa mahindi pekee, wiki 3–4 baada ya kupanda',
    prevention: 'Mbolea za nitrogen zinasaidia mazao kushinda magugu. '
        'Mulch ya majani mazito inazuia mbegu kumea.',
  ),
  _Threat(
    emoji: '🌻',
    nameSw: 'Euphobia (Msururu)',
    nameEn: 'Spurge (Euphorbia heterophylla)',
    symptoms:
        'Mmea wenye majani yenye doa nyekundu/njano chini, utomvu mweupe ukikatwa.',
    immediateAction: 'Ng\'oa kabla ya kutoa mbegu. Vaa glovu — utomvu unawasha ngozi.',
    dawa1: 'Atrazine 500SC',
    dawa1Dose: '50ml kwa dumu la lita 15 — kwa mahindi tu, kabla ya mazao kuota',
    prevention: 'Lima kina kirefu kwanza. Zungusha mazao mara kwa mara.',
  ),
];

const _haliYaHewaThreats = <_Threat>[
  _Threat(
    emoji: '🌡️',
    nameSw: 'Upungufu wa Nitrojeni (N)',
    nameEn: 'Nitrogen Deficiency',
    symptoms:
        'Majani ya chini yanageuka njano kuanza katika mstari wa kati wa jani. '
        'Mmea ni mfupi na unaonekana mdhaifu. Mazao yanakuwa kidogo.',
    immediateAction:
        'Piga mbolea ya CAN (Calcium Ammonium Nitrate) mara moja. '
        'Au tumia Urea kwa mazao ya safu kama mahindi.',
    dawa1: 'CAN (Calcium Ammonium Nitrate 27%N)',
    dawa1Dose: '50kg kwa ekari moja — weka pembeni ya mmea, usiweke juu ya mmea',
    dawa2: 'Urea (46%N)',
    dawa2Dose: '25kg kwa ekari moja — wiki 4–6 baada ya kupanda',
    prevention:
        'Panda mbegu pamoja na mbolea ya DAP wakati wa kupanda. '
        'Kila mwaka jaribu udongo ili kujua kiwango cha virutubisho.',
  ),
  _Threat(
    emoji: '💧',
    nameSw: 'Upungufu wa Maji (Ukame)',
    nameEn: 'Water Stress / Drought',
    symptoms:
        'Majani yanajisokota mchana (kunyauka). Rangi ya mmea inageuka kijivu-kijani. '
        'Mmea unadumaa na mazao kidogo au hayakomaa.',
    immediateAction:
        'Mwagilia mara moja — asubuhi 6am–8am au jioni 5pm–7pm (si mchana). '
        'Tia mulch ili kupunguza uvukizi.',
    dawa1: 'Profiler WG — kuzuia Phytophthora inayoshambulia wakati mmea dhaifu',
    dawa1Dose: 'Tumia dawa za ukungu preventively wakati wa mfadhaiko wa maji',
    prevention:
        'Chimba mitaro ya kuhifadhi maji (conservation furrows). '
        'Tumia mulch ya nyasi au mabaki ya mazao. '
        'Panda aina za mazao zinazostahimili ukame: DK8031 (mahindi), SEEDCO SC403.',
  ),
  _Threat(
    emoji: '🌊',
    nameSw: 'Maji Mengi / Mafuriko',
    nameEn: 'Waterlogging / Flood Stress',
    symptoms:
        'Majani yanageuka njano kwa haraka. Mizizi inaoza. '
        'Harufu mbaya kutoka ardhini. Mmea unalegea na kuanguka.',
    immediateAction:
        'Chimba mifereji ya kumwaga maji haraka. Ondoa maji yaliyosimama. '
        'Weka CAN kidogo ili kusaidia mmea kupona.',
    dawa1: 'Copper Oxychloride 50WP (kuzuia magonjwa ya mizizi)',
    dawa1Dose: '30g kwa dumu la lita 15 — loweka ardhi baada ya maji kupungua',
    prevention:
        'Panda kwenye matuta (raised beds). Panga mashamba yenye mifereji. '
        'Epuka kupanda kwenye maeneo ya chini kabla ya mvua kubwa.',
  ),
  _Threat(
    emoji: '🌿',
    nameSw: 'Upungufu wa Zinki (Zn)',
    nameEn: 'Zinc Deficiency',
    symptoms:
        'Majani mapya yanageuka njano huku mishipa ikiwa bado kijani (interveinal chlorosis). '
        'Mimea inaonekana kama imetiwa rangi ya blanketi. Kawaida kwenye udongo wa mchanga.',
    immediateAction: 'Piga Zinc Sulphate mara moja kwenye majani au ardhini.',
    dawa1: 'Zinc Sulphate 21%',
    dawa1Dose: '5g kwa dumu la lita 15 (foliar spray) AU 10kg/ekari (ardhini)',
    prevention:
        'Ongeza compost (mboji) kwenye udongo wa mchanga kila mwaka. '
        'Tumia mbolea za NPK zenye zinki (Yara Mila ACTYVA au sawa).',
  ),
];

// ── Crop list ─────────────────────────────────────────────────────────────────

const _kCropsProtection = [
  'Mahindi', 'Nyanya', 'Maharagwe', 'Muhogo', 'Mchele',
  'Ndizi', 'Pilipili hoho', 'Alizeti', 'Pamba', 'Viazi vitamu',
  'Mtama', 'Karanga', 'Soya', 'Ngano', 'Vitunguu',
];

// ── Main screen ───────────────────────────────────────────────────────────────

class CropProtectionScreen extends StatefulWidget {
  const CropProtectionScreen({super.key});

  @override
  State<CropProtectionScreen> createState() => _CropProtectionScreenState();
}

class _CropProtectionScreenState extends State<CropProtectionScreen> {
  // which category section is expanded (null = all collapsed)
  int? _expandedSection;

  static const _sections = [
    {'emoji': '🐛', 'title': 'Wadudu na Nzige', 'subtitle': 'Insects & Locusts', 'color': 0xFFE65100},
    {'emoji': '🍄', 'title': 'Ukungu na Magonjwa', 'subtitle': 'Fungal & Bacterial Diseases', 'color': 0xFF6A1B9A},
    {'emoji': '🌿', 'title': 'Magugu', 'subtitle': 'Weeds & Herbicides', 'color': 0xFF2E7D32},
    {'emoji': '🌡️', 'title': 'Hali ya Hewa & Lishe', 'subtitle': 'Weather Stress & Nutrients', 'color': 0xFF0277BD},
  ];

  static const _threatsPerSection = [
    _waduduThreats,
    _magonjwaThreats,
    _maguguThreats,
    _haliYaHewaThreats,
  ];

  @override
  Widget build(BuildContext context) {
    final emergencies = [
      ..._waduduThreats.where((t) => t.isEmergency),
      ..._magonjwaThreats.where((t) => t.isEmergency),
      ..._maguguThreats.where((t) => t.isEmergency),
    ];

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: Text(
          'Ulinzi wa Mazao',
          style: GoogleFonts.playfairDisplay(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Diagnosis action buttons ──────────────────────────────────────
          _buildDiagnosisActions(context),

          const SizedBox(height: 20),

          // ── Emergency alert (locusts / armyworm / CMD) ────────────────────
          if (emergencies.isNotEmpty) ...[
            _buildEmergencyBanner(context, emergencies),
            const SizedBox(height: 20),
          ],

          // ── Category sections ─────────────────────────────────────────────
          Text(
            'Magonjwa na Matatizo ya Mazao',
            style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.mid),
          ),
          const SizedBox(height: 10),

          for (int i = 0; i < _sections.length; i++) ...[
            _buildCategoryCard(i),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 12),

          // ── Spray safety reminder ─────────────────────────────────────────
          _buildSpraySafety(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Diagnosis action buttons ──────────────────────────────────────────────

  Widget _buildDiagnosisActions(BuildContext context) {
    return Column(
      children: [
        // Primary: photo scan
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.leaf,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.camera_alt, size: 22),
            label: Text('Piga Picha ya Jani — Gundua Ugonjwa',
                style: GoogleFonts.dmSans(
                    fontSize: 15, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ScanScreen())),
          ),
        ),
        const SizedBox(height: 10),
        // Secondary: text symptoms
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.soil,
              side: BorderSide(color: AppColors.mid.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.edit_note, size: 22),
            label: Text('Elezea Dalili kwa Maneno (Bila Picha)',
                style: GoogleFonts.dmSans(fontSize: 14)),
            onPressed: () => _openTextDiagnosisSheet(context),
          ),
        ),
      ],
    );
  }

  // ── Emergency banner ──────────────────────────────────────────────────────

  Widget _buildEmergencyBanner(
      BuildContext context, List<_Threat> emergencies) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'DHARURA — Vitisho vya Haraka',
                  style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
              ],
            ),
          ),
          ...emergencies.map(
            (t) => InkWell(
              onTap: () => _showThreatDetail(context, t),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(t.emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.nameSw,
                              style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          Text(t.immediateAction,
                              style: GoogleFonts.dmSans(
                                  color: Colors.white70, fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: Colors.white70, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category expandable card ──────────────────────────────────────────────

  Widget _buildCategoryCard(int index) {
    final section = _sections[index];
    final threats = _threatsPerSection[index];
    final color = Color(section['color'] as int);
    final isExpanded = _expandedSection == index;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() =>
                _expandedSection = isExpanded ? null : index),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                border: Border(
                    left: BorderSide(color: color, width: 4)),
              ),
              child: Row(
                children: [
                  Text(section['emoji'] as String,
                      style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section['title'] as String,
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.soil)),
                        Text(section['subtitle'] as String,
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${threats.length}',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: color,
                  ),
                ],
              ),
            ),
          ),

          // Expanded threat list
          if (isExpanded)
            Column(
              children: threats
                  .map((t) => _buildThreatTile(context, t, color))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildThreatTile(
      BuildContext context, _Threat t, Color sectionColor) {
    return InkWell(
      onTap: () => _showThreatDetail(context, t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: AppColors.mid.withValues(alpha: 0.1))),
        ),
        child: Row(
          children: [
            Text(t.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(t.nameSw,
                            style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.soil)),
                      ),
                      if (t.isEmergency)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB71C1C)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('DHARURA',
                              style: TextStyle(
                                  color: Color(0xFFB71C1C),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(t.nameEn,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    t.symptoms,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF555555)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.info_outline, color: sectionColor, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Spray safety reminder ─────────────────────────────────────────────────

  Widget _buildSpraySafety() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0277BD).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF0277BD).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Color(0xFF0277BD), size: 18),
              const SizedBox(width: 8),
              Text(
                'Usalama wa Kupiga Dawa',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0277BD),
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...const [
            '🌬️ Piga dawa asubuhi mapema (6am–9am) au jioni (4pm–6pm) — upepo mdogo',
            '🌧️ Usipige dawa kama mvua inatarajiwa ndani ya saa 4',
            '🧤 Vaa glovu, miwani na gauni la kujikinga kila wakati',
            '🚫 Usinywe, usile, wala kuvuta sigara ukipiga dawa',
            '📏 Fuata kipimo sahihi — dawa nyingi ni hasara, si faida',
            '🏷️ Tumia dawa zilizosajiliwa TPRI/TFDA Tanzania pekee',
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(tip,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.mid)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Threat detail bottom sheet ────────────────────────────────────────────

  void _showThreatDetail(BuildContext context, _Threat threat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, ctrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Text(threat.emoji,
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(threat.nameSw,
                            style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.soil)),
                        Text(threat.nameEn,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  if (threat.isEmergency)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB71C1C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('DHARURA',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Symptoms
              _detailSection(
                icon: Icons.search,
                color: const Color(0xFF1565C0),
                title: 'Dalili (Symptoms)',
                body: threat.symptoms,
              ),

              const SizedBox(height: 16),

              // Immediate action
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6F00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFF6F00).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber,
                            color: Color(0xFFFF6F00), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Hatua ya Haraka — Fanya SASA',
                          style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFF6F00),
                              fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(threat.immediateAction,
                        style: GoogleFonts.dmSans(
                            fontSize: 13, color: AppColors.soil)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Pesticides
              _detailSection(
                icon: Icons.science,
                color: const Color(0xFF6A1B9A),
                title: 'Dawa Zinazopendekezwa (TPRI Tanzania)',
                body: '',
              ),
              _pesticideRow('1', threat.dawa1, threat.dawa1Dose),
              if (threat.dawa2.isNotEmpty) ...[
                const SizedBox(height: 8),
                _pesticideRow('2', threat.dawa2, threat.dawa2Dose),
              ],

              const SizedBox(height: 16),

              // Prevention
              _detailSection(
                icon: Icons.shield,
                color: const Color(0xFF2E7D32),
                title: 'Kinga na Uzuiaji',
                body: threat.prevention,
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Piga Picha kwa Uthibitisho Zaidi'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ScanScreen()));
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailSection({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(title,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13)),
          ],
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(body,
              style:
                  GoogleFonts.dmSans(fontSize: 13, color: AppColors.soil)),
        ],
      ],
    );
  }

  Widget _pesticideRow(String num, String name, String dose) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFF6A1B9A),
          child: Text(num,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.soil)),
              Text(dose,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Text diagnosis sheet ──────────────────────────────────────────────────

  void _openTextDiagnosisSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TextDiagnosisSheet(),
    );
  }
}

// ── Text Diagnosis bottom sheet ───────────────────────────────────────────────

class _TextDiagnosisSheet extends StatefulWidget {
  const _TextDiagnosisSheet();

  @override
  State<_TextDiagnosisSheet> createState() => _TextDiagnosisSheetState();
}

class _TextDiagnosisSheetState extends State<_TextDiagnosisSheet> {
  String _selectedCrop = _kCropsProtection.first;
  final _symptomsCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _symptomsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: ctrl,
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('Elezea Tatizo Lako',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.soil)),
            const SizedBox(height: 4),
            Text(
              'AI itachunguza dalili unazozielezea na kutoa ushauri wa dawa.',
              style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 20),

            // Crop picker
            Text('Zao:',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _kCropsProtection
                  .map((crop) => ChoiceChip(
                        label: Text(crop,
                            style: TextStyle(
                                fontSize: 12,
                                color: _selectedCrop == crop
                                    ? Colors.white
                                    : AppColors.soil)),
                        selected: _selectedCrop == crop,
                        onSelected: (_) =>
                            setState(() => _selectedCrop = crop),
                        selectedColor: AppColors.leaf,
                        backgroundColor:
                            AppColors.mint.withValues(alpha: 0.5),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 20),

            // Symptoms text field
            Text('Elezea Dalili (kwa Kiswahili au Kiingereza):',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _symptomsCtrl,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText:
                    'Mfano: Mahindi yangu yana matundu makubwa kwenye majani. '
                    'Ninaona viumbe vidogo vya rangi kijani/njano... '
                    'Dalili zilianza wiki mbili zilizopita.',
                hintStyle:
                    const TextStyle(color: Colors.grey, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.mid.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.mid.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.leaf, width: 2),
                ),
                filled: true,
                fillColor: AppColors.mint.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              '💡 Elezea vizuri: rangi, sehemu iliyoathirika, '
              'muda dalili zilianza, na hali ya hewa hivi karibuni.',
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.leaf,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.psychology),
                label: Text(
                  _loading ? 'AI Inachunguza...' : 'Chunguza kwa AI',
                  style: GoogleFonts.dmSans(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                onPressed: _loading ? null : _runDiagnosis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runDiagnosis() async {
    final symptoms = _symptomsCtrl.text.trim();
    if (symptoms.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tafadhali elezea dalili vizuri zaidi (maneno 10+).')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await ClaudeService.diagnoseBySymptoms(
        cropName: _selectedCrop,
        symptomsDescription: symptoms,
      );

      if (!mounted) return;
      Navigator.pop(context); // close sheet

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            diagnosis: result,
            imagePath: '',
            cropName: _selectedCrop,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: ${e.toString()}')),
      );
    }
  }
}
