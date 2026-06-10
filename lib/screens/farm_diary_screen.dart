import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

// ── Farm Diary Screen ─────────────────────────────────────────────────────────

class FarmDiaryScreen extends StatefulWidget {
  final String? farmId;
  final String? farmName;
  const FarmDiaryScreen({super.key, this.farmId, this.farmName});

  @override
  State<FarmDiaryScreen> createState() => _FarmDiaryScreenState();
}

class _FarmDiaryScreenState extends State<FarmDiaryScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _loading = false;
  String? _filterType;
  static SupabaseClient get _db => Supabase.instance.client;

  static const _eventTypes = [
    'Zote', 'Kupanda', 'Mbolea', 'Palizi', 'Umwagiliaji',
    'Ugonjwa', 'Kupulizia', 'Kuvuna', 'Upimaji wa Udongo',
    'Picha ya Setilaiti', 'Kumbumbu',
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _loading = true);
    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      var query = _db.from('farm_events').select();
      if (userId != null) query = query.eq('farmer_id', userId) as dynamic;
      if (widget.farmId != null) query = query.eq('farm_id', widget.farmId!) as dynamic;
      if (_filterType != null && _filterType != 'Zote') {
        query = query.eq('event_type', _filterType!) as dynamic;
      }
      final rows = await query.order('event_date', ascending: false).limit(50);
      if (mounted) {
        setState(() => _events = (rows as List)
            .map((r) => Map<String, dynamic>.from(r)).toList());
      }
    } catch (e) {
      // Demo data
      if (mounted) setState(() => _events = _demoEvents());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _demoEvents() => [
    {
      'id': '1', 'event_type': 'Kupanda', 'event_date': DateTime.now()
          .subtract(const Duration(days: 45)).toIso8601String(),
      'crop_name': 'Mahindi', 'description': 'Kupanda mbegu za SC403',
      'cost_tzs': 25000, 'notes': 'Mvua nzuri ilisaidia',
    },
    {
      'id': '2', 'event_type': 'Mbolea', 'event_date': DateTime.now()
          .subtract(const Duration(days: 38)).toIso8601String(),
      'crop_name': 'Mahindi', 'description': 'DAP 50kg/ekari kupanda',
      'cost_tzs': 45000, 'product_used': 'DAP', 'quantity': 50.0, 'quantity_unit': 'kg',
    },
    {
      'id': '3', 'event_type': 'Ugonjwa', 'event_date': DateTime.now()
          .subtract(const Duration(days: 20)).toIso8601String(),
      'crop_name': 'Mahindi', 'description': 'Fall Armyworm iligunduliwa',
      'cost_tzs': 35000, 'notes': 'Kushambuliwa wastani',
    },
    {
      'id': '4', 'event_type': 'Kupulizia', 'event_date': DateTime.now()
          .subtract(const Duration(days: 18)).toIso8601String(),
      'crop_name': 'Mahindi', 'description': 'Emamectin benzoate dhidi ya FAW',
      'cost_tzs': 18000, 'product_used': 'Emamectin', 'quantity': 1.0, 'quantity_unit': 'lita',
    },
    {
      'id': '5', 'event_type': 'Palizi', 'event_date': DateTime.now()
          .subtract(const Duration(days: 10)).toIso8601String(),
      'crop_name': 'Mahindi', 'description': 'Palizi ya mikono (siku 2)',
      'cost_tzs': 20000, 'labour_workers': 4,
    },
  ];

  String _eventEmoji(String type) {
    const map = {
      'Kupanda': '🌱', 'Mbolea': '💊', 'Palizi': '🌿',
      'Umwagiliaji': '💧', 'Ugonjwa': '🦠', 'Kupulizia': '🧪',
      'Kuvuna': '🌾', 'Upimaji wa Udongo': '📏',
      'Picha ya Setilaiti': '📸', 'Kumbumbu': '📝',
    };
    return map[type] ?? '📝';
  }

  Color _eventColor(String type) {
    const map = {
      'Kupanda': Color(0xFF2E7D32), 'Mbolea': Color(0xFF6A1B9A),
      'Palizi': Color(0xFF2E8B57), 'Umwagiliaji': Color(0xFF0277BD),
      'Ugonjwa': Color(0xFFB71C1C), 'Kupulizia': Color(0xFFE65100),
      'Kuvuna': Color(0xFFC8860A), 'Upimaji wa Udongo': Color(0xFF4E342E),
      'Picha ya Setilaiti': Color(0xFF1565C0), 'Kumbumbu': Color(0xFF546E7A),
    };
    return map[type] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.farmName != null ? '${widget.farmName} — Diari' : 'Diari ya Shamba'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEvents),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
            MaterialPageRoute(builder: (_) => AddFarmEventScreen(farmId: widget.farmId)));
          _loadEvents();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Ongeza', style: GoogleFonts.poppins(
            color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _eventTypes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final type = _eventTypes[i];
                final sel = (type == 'Zote' && _filterType == null) ||
                    type == _filterType;
                return GestureDetector(
                  onTap: () {
                    setState(() => _filterType = type == 'Zote' ? null : type);
                    _loadEvents();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.primary : Colors.grey.shade300),
                    ),
                    child: Text(type,
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: sel ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          // Events list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _events.isEmpty
                    ? Center(child: Text(
                        'Hakuna matukio bado.\nGonga + kuongeza.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _EventCard(
                          event: _events[i],
                          emoji: _eventEmoji(_events[i]['event_type'] ?? ''),
                          color: _eventColor(_events[i]['event_type'] ?? ''),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final String emoji;
  final Color color;
  const _EventCard({required this.event, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    final dateStr = event['event_date'] as String? ?? '';
    final date = DateTime.tryParse(dateStr);
    final dateFormatted = date != null
        ? DateFormat('dd MMM yyyy').format(date)
        : dateStr;
    final cost = event['cost_tzs'] as int?;
    final costStr = cost != null
        ? cost.toString().replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadow.xs,
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(emoji,
                style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(event['event_type'] ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                  const Spacer(),
                  Text(dateFormatted,
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                ]),
                const SizedBox(height: 6),
                if (event['crop_name'] != null)
                  Text(event['crop_name'] as String,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                if (event['description'] != null)
                  Text(event['description'] as String,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                if (event['product_used'] != null)
                  Text('Bidhaa: ${event['product_used']}${event['quantity'] != null ? ' — ${event['quantity']} ${event['quantity_unit'] ?? ''}' : ''}',
                      style: GoogleFonts.poppins(fontSize: 12)),
                if (event['notes'] != null)
                  Text(event['notes'] as String,
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontStyle: FontStyle.italic,
                          color: Colors.grey)),
                if (costStr != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.attach_money, size: 14, color: Colors.grey),
                    Text('TZS $costStr',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add Farm Event Screen ─────────────────────────────────────────────────────

class AddFarmEventScreen extends StatefulWidget {
  final String? farmId;
  const AddFarmEventScreen({super.key, this.farmId});

  @override
  State<AddFarmEventScreen> createState() => _AddFarmEventScreenState();
}

class _AddFarmEventScreenState extends State<AddFarmEventScreen> {
  String _eventType = 'Kupanda';
  final _cropCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _qtyUnitCtrl = TextEditingController(text: 'kg');
  DateTime _eventDate = DateTime.now();
  bool _saving = false;

  static const _types = [
    '🌱 Kupanda', '💊 Mbolea', '🌿 Palizi', '💧 Umwagiliaji',
    '🦠 Ugonjwa', '🧪 Kupulizia', '🌾 Kuvuna',
    '📏 Upimaji wa Udongo', '📝 Kumbumbu',
  ];

  static SupabaseClient get _db => Supabase.instance.client;

  @override
  void dispose() {
    _cropCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    _costCtrl.dispose();
    _productCtrl.dispose();
    _qtyCtrl.dispose();
    _qtyUnitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_cropCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza jina la zao')));
      return;
    }
    setState(() => _saving = true);
    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      await _db.from('farm_events').insert({
        'farmer_id': userId,
        'farm_id': widget.farmId,
        'event_type': _eventType,
        'event_date': _eventDate.toIso8601String(),
        'crop_name': _cropCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'cost_tzs': int.tryParse(_costCtrl.text.trim()),
        'product_used': _productCtrl.text.trim().isEmpty ? null : _productCtrl.text.trim(),
        'quantity': double.tryParse(_qtyCtrl.text.trim()),
        'quantity_unit': _qtyUnitCtrl.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Tukio limehifadhiwa!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hitilafu: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Ongeza Tukio'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('HIFADHI',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event type
            Text('Aina ya Tukio',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _types.map((t) {
                final type = t.substring(2).trim();
                final sel = type == _eventType;
                return GestureDetector(
                  onTap: () => setState(() => _eventType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: sel ? AppColors.primary : Colors.grey.shade300),
                    ),
                    child: Text(t,
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: sel ? Colors.white : Colors.black87)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Date picker
            _FormField(
              label: '📅 Tarehe',
              child: InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _eventDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (d != null) setState(() => _eventDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border.fromBorderSide(
                      BorderSide(color: Color(0xFFDDDDDD))),
                  ),
                  child: Row(children: [
                    Text(DateFormat('dd MMMM yyyy').format(_eventDate),
                        style: GoogleFonts.poppins(fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.calendar_today_outlined, color: Colors.grey),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _FormField(
              label: '🌱 Zao',
              child: TextField(
                controller: _cropCtrl,
                decoration: InputDecoration(
                  hintText: 'Mfano: Mahindi, Nyanya...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _FormField(
              label: '📝 Maelezo',
              child: TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Elezea tukio kwa ufupi...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (_showProductFields()) ...[
              Row(children: [
                Expanded(child: _FormField(
                  label: '🧴 Bidhaa',
                  child: TextField(
                    controller: _productCtrl,
                    decoration: InputDecoration(
                      hintText: 'Jina la bidhaa...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )),
                const SizedBox(width: 10),
                SizedBox(width: 80, child: _FormField(
                  label: '⚖️ Kiasi',
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )),
                const SizedBox(width: 8),
                SizedBox(width: 60, child: _FormField(
                  label: 'Kipimo',
                  child: TextField(
                    controller: _qtyUnitCtrl,
                    decoration: InputDecoration(
                      hintText: 'kg',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                )),
              ]),
              const SizedBox(height: 12),
            ],

            _FormField(
              label: '💵 Gharama (TZS)',
              child: TextField(
                controller: _costCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Mfano: 25000',
                  prefixText: 'TZS ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            _FormField(
              label: '💬 Maelezo Zaidi (hiari)',
              child: TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Maelezo zaidi...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52)),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Hifadhi Tukio',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  bool _showProductFields() => ['Mbolea', 'Kupulizia', 'Palizi'].contains(_eventType);
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
