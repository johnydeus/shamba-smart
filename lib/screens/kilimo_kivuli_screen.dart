import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class KilimoKivuliScreen extends StatefulWidget {
  const KilimoKivuliScreen({super.key});

  @override
  State<KilimoKivuliScreen> createState() => _KilimoKivuliScreenState();
}

class _KilimoKivuliScreenState extends State<KilimoKivuliScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('🌿 Kilimo Kivuli'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFFFFB300),
          tabs: const [
            Tab(text: 'Mwongozo'),
            Tab(text: 'Hesabu Faida'),
            Tab(text: 'Magonjwa'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildGuideTab(),
          _buildRoiTab(),
          _buildDiseaseTab(),
        ],
      ),
    );
  }

  Widget _buildGuideTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌿', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('Kilimo Kivuli',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontSize: 24,
                        fontWeight: FontWeight.w800)),
                Text('Ongeza Mavuno — Piga Mbio Msimu',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFF95D5B2), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Aina za Kilimo Kivuli',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),

          _StructureCard(
            emoji: '🏠', title: 'Netiŋ / Shade Net',
            description: 'Chaguo la bei nafuu zaidi. Hupunguza jua kali '
                'na kuepuka mvua kubwa.',
            cost: '150,000–500,000 TZS / ekari',
            yieldIncrease: '25–35%',
            payback: 'Msimu 1–2',
            color: const Color(0xFF2E8B57),
          ),
          const SizedBox(height: 10),
          _StructureCard(
            emoji: '🏕️', title: 'Plastic Tunnel (Chini)',
            description: 'Kipande cha plastiki kinachofunika mazao. '
                'Hudhibiti joto na unyevu vizuri zaidi.',
            cost: '800,000–2,500,000 TZS / ekari',
            yieldIncrease: '40–60%',
            payback: 'Miezi 6–12',
            color: const Color(0xFF0277BD),
          ),
          const SizedBox(height: 10),
          _StructureCard(
            emoji: '🏭', title: 'Greenhouse (Kamili)',
            description: 'Udhibiti kamili wa mazingira. Bei kubwa '
                'lakini faida kubwa sana.',
            cost: '5,000,000–15,000,000 TZS / ekari',
            yieldIncrease: '80–200%',
            payback: 'Miaka 2–3',
            color: const Color(0xFF6A1B9A),
          ),
          const SizedBox(height: 24),

          Text('Mazao Yanayofanya Vizuri',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: const [
              _CropCard(emoji: '🍅', name: 'Nyanya',
                  increase: '+60%', type: 'Tunnel / Greenhouse'),
              _CropCard(emoji: '🌶️', name: 'Pilipili',
                  increase: '+45%', type: 'Shade Net / Tunnel'),
              _CropCard(emoji: '🧅', name: 'Vitunguu',
                  increase: '+40%', type: 'Shade Net'),
              _CropCard(emoji: '🥬', name: 'Mbogamboga',
                  increase: '+50%', type: 'Shade Net'),
              _CropCard(emoji: '🌸', name: 'Maua',
                  increase: '+200%', type: 'Greenhouse'),
              _CropCard(emoji: '🥒', name: 'Tango',
                  increase: '+55%', type: 'Tunnel'),
            ],
          ),
          const SizedBox(height: 24),

          // Suppliers section
          Text('Wapi Kununua Tanzania',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          _SupplierCard(
            name: 'Agrimall Tanzania',
            location: 'Dar es Salaam — Mikocheni',
            phone: '+255 22 000 0000',
            products: ['Shade net', 'Plastic film'],
          ),
          const SizedBox(height: 8),
          _SupplierCard(
            name: 'Afri-Input Solutions',
            location: 'Arusha — Njiro',
            phone: '+255 27 000 0000',
            products: ['Greenhouse structures', 'Drip irrigation'],
          ),
          const SizedBox(height: 8),
          _SupplierCard(
            name: 'Kilimo Materials Moshi',
            location: 'Moshi — Kati mji',
            phone: '+255 755 000 000',
            products: ['Shade net', 'Metal frames'],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRoiTab() {
    return const _RoiCalculator();
  }

  Widget _buildDiseaseTab() {
    final diseases = [
      {
        'emoji': '🍄', 'name': 'Botrytis (Ukungu wa Kijivu)',
        'cause': 'Unyevu kupita kiasi',
        'symptoms': 'Majani na matunda yanakuwa na manyoya ya kijivu',
        'treatment': 'Punguza unyevu, onyesha hewa, tumia fungicide ya iprodione',
        'prevention': 'Mwagilia chini tu (drip), epuka kumwagilia majani',
      },
      {
        'emoji': '🌑', 'name': 'Powdery Mildew (Unga Mweupe)',
        'cause': 'Joto kali + hewa ya unyevu ndani',
        'symptoms': 'Unga mweupe kwenye majani',
        'treatment': 'Piga dawa za salfa au fungicide ya bicarbonate',
        'prevention': 'Ventilation nzuri, epuka joto kupita kiasi',
      },
      {
        'emoji': '🌊', 'name': 'Root Rot (Kuoza kwa Mizizi)',
        'cause': 'Mwagilio kupita kiasi',
        'symptoms': 'Mmea unakufa ghafla, mizizi nyeusi',
        'treatment': 'Toa mmea, sasisha udongo, tumia fungicide ya metalaxyl',
        'prevention': 'Drip irrigation, udongo wa mifereji mizuri',
      },
      {
        'emoji': '🔴', 'name': 'Tuta absoluta (Funza wa Nyanya)',
        'cause': 'Wadudu wanaofanana na nondo wadogo',
        'symptoms': 'Machimbo kwenye majani, matunda yaliyoharibika',
        'treatment': 'Mtego wa pheromone, Spinosad 50ml/15L',
        'prevention': 'Netiŋ ya kuepuka wadudu (insect net)',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: diseases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _DiseaseCard(disease: diseases[i]),
    );
  }
}

class _StructureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final String cost;
  final String yieldIncrease;
  final String payback;
  final Color color;

  const _StructureCard({
    required this.emoji, required this.title, required this.description,
    required this.cost, required this.yieldIncrease,
    required this.payback, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: AppShadow.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(child: Text(title,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 15))),
          ]),
          const SizedBox(height: 8),
          Text(description,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, height: 1.5)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            _InfoChip(icon: '💰', label: cost, color: color),
            _InfoChip(icon: '📈', label: 'Mavuno: $yieldIncrease', color: color),
            _InfoChip(icon: '⏱️', label: 'Faida: $payback', color: color),
          ]),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$icon $label',
          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _CropCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String increase;
  final String type;
  const _CropCard({required this.emoji, required this.name,
    required this.increase, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const Spacer(),
          Text(name, style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, fontSize: 14)),
          Text(increase, style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w800,
              color: const Color(0xFF2E7D32))),
          Text(type, style: GoogleFonts.poppins(
              fontSize: 9, color: Colors.grey),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final String name;
  final String location;
  final String phone;
  final List<String> products;
  const _SupplierCard({
    required this.name, required this.location,
    required this.phone, required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppShadow.xs,
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.store_outlined, color: AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            Text(location, style: GoogleFonts.poppins(
                fontSize: 12, color: Colors.grey)),
            Text(products.join(' • '), style: GoogleFonts.poppins(
                fontSize: 11, color: AppColors.primary)),
          ],
        )),
        Column(children: [
          Text(phone, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
        ]),
      ]),
    );
  }
}

class _DiseaseCard extends StatefulWidget {
  final Map<String, dynamic> disease;
  const _DiseaseCard({required this.disease});

  @override
  State<_DiseaseCard> createState() => _DiseaseCardState();
}

class _DiseaseCardState extends State<_DiseaseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.disease;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.sm,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(d['emoji'] as String, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(child: Text(d['name'] as String,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 14))),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey),
              ]),
              const SizedBox(height: 4),
              Text('Sababu: ${d['cause']}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              if (_expanded) ...[
                const SizedBox(height: 12),
                _DetailSection(icon: '🔍', label: 'Dalili', text: d['symptoms']),
                _DetailSection(icon: '💊', label: 'Matibabu', text: d['treatment']),
                _DetailSection(icon: '🛡️', label: 'Kinga', text: d['prevention']),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String icon;
  final String label;
  final String text;
  const _DetailSection({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 12)),
              Text(text, style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey.shade700, height: 1.5)),
            ],
          )),
        ],
      ),
    );
  }
}

// ── ROI Calculator ────────────────────────────────────────────────────────────

class _RoiCalculator extends StatefulWidget {
  const _RoiCalculator();

  @override
  State<_RoiCalculator> createState() => _RoiCalculatorState();
}

class _RoiCalculatorState extends State<_RoiCalculator> {
  String _structure = 'Shade Net';
  String _crop = 'Nyanya';
  double _size = 0.5; // acres
  int _currentYield = 2000; // kg/acre
  int _marketPrice = 1200; // TZS/kg

  static const _structureCosts = {
    'Shade Net': 300000, 'Plastic Tunnel': 1500000, 'Greenhouse': 10000000};
  static const _yieldMultipliers = {
    'Shade Net': 1.30, 'Plastic Tunnel': 1.50, 'Greenhouse': 1.80};

  int get _structureCost =>
      ((_structureCosts[_structure] ?? 0) * _size).round();
  double get _newYield =>
      _currentYield * (_yieldMultipliers[_structure] ?? 1.3);
  int get _extraYield => (_newYield - _currentYield).round();
  int get _extraRevenue =>
      (_extraYield * _size * _marketPrice).round();
  int get _inputCost => (_size * 200000).round();
  int get _netGain => _extraRevenue - _inputCost;
  double get _paybackMonths =>
      _netGain > 0 ? _structureCost / (_netGain / 6) : 99;

  @override
  Widget build(BuildContext context) {
    final costStr = _structureCost.toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    final gainStr = _netGain.toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hesabu Faida Yako',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 4),
          Text('Ingiza takwimu zako kupata makadirio',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),

          // Structure
          _Label('Aina ya Muundo'),
          Row(children: ['Shade Net', 'Plastic Tunnel', 'Greenhouse']
              .map((s) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _structure = s),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _structure == s ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _structure == s
                              ? AppColors.primary : Colors.grey.shade300),
                      ),
                      child: Text(s,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: _structure == s ? Colors.white : Colors.black87)),
                    ),
                  )))
              .toList()),
          const SizedBox(height: 16),

          // Size slider
          _Label('Ukubwa wa Shamba: ${_size.toStringAsFixed(1)} ekari'),
          Slider(
            value: _size, min: 0.1, max: 5.0, divisions: 49,
            label: '${_size.toStringAsFixed(1)} ekari',
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _size = v),
          ),
          const SizedBox(height: 12),

          // Crop
          _Label('Zao'),
          DropdownButtonFormField<String>(
            value: _crop,
            decoration: InputDecoration(border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12))),
            items: ['Nyanya', 'Pilipili', 'Vitunguu', 'Tango', 'Mbogamboga', 'Maua']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _crop = v!),
          ),
          const SizedBox(height: 12),

          // Current yield
          _Label('Mavuno ya Sasa (kg/ekari): $_currentYield kg'),
          Slider(
            value: _currentYield.toDouble(), min: 500, max: 10000, divisions: 19,
            label: '$_currentYield kg',
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _currentYield = v.round()),
          ),
          const SizedBox(height: 12),

          // Market price
          _Label('Bei ya Soko (TZS/kg): $_marketPrice'),
          Slider(
            value: _marketPrice.toDouble(), min: 200, max: 5000, divisions: 48,
            label: '$_marketPrice TZS',
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _marketPrice = v.round()),
          ),
          const SizedBox(height: 24),

          // Results
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadow.md,
            ),
            child: Column(children: [
              Text('Matokeo ya Makadirio',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const Divider(height: 20),
              _ResultRow('Gharama ya Muundo', 'TZS $costStr'),
              _ResultRow('Mavuno ya Ziada', '${_extraYield.round()} kg/ekari'),
              _ResultRow('Mapato ya Ziada', 'TZS $gainStr/msimu'),
              _ResultRow('Muda wa Kurudisha Pesa',
                  '${_paybackMonths.toStringAsFixed(1)} miezi'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _netGain > 0
                      ? AppColors.primarySoft
                      : AppColors.criticalBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _netGain > 0
                      ? '✅ Mradi huu unafaa kiuchumi!'
                      : '⚠️ Hesabu upya — gharama ni kubwa sana',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: _netGain > 0
                          ? AppColors.primary
                          : AppColors.critical),
                  textAlign: TextAlign.center,
                ),
              ),
            ]),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(child: Text(label,
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey))),
        Text(value, style: GoogleFonts.poppins(
            fontSize: 14, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
