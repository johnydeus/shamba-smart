import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/listing_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/listing_provider.dart';
import 'chat_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/common_widgets.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _tzs(int amount) {
  final s = amount.toString();
  final buf = StringBuffer();
  final mod = s.length % 3;
  for (int i = 0; i < s.length; i++) {
    if (i != 0 && (i - mod) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return 'TZS ${buf.toString()}';
}

Color _hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// Swahili month names for date display
const _months = [
  'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
  'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'
];

String _fmtDate(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year}';

// ─── Marketplace Screen ────────────────────────────────────────────────────────

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listings = context.watch<ListingProvider>();
    final displayed = listings.filteredListings;

    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: Text('Soko la Shamba Smart',
            style: GoogleFonts.playfairDisplay(
                color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () => _openAddListing(context),
            icon: const Icon(Icons.add, color: AppColors.sun),
            label: Text('Ongeza',
                style: GoogleFonts.dmSans(
                    color: AppColors.sun,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: listings.searchListings,
              decoration: InputDecoration(
                hintText: 'Tafuta bidhaa, mahali, au muuzaji...',
                hintStyle:
                    GoogleFonts.dmSans(color: AppColors.mid, fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.mid),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.mid, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          listings.searchListings('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // ── Category chips ──────────────────────────────────────────────
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              children: [
                // "Yote" chip
                _CategoryChip(
                  label: 'Yote',
                  emoji: '🛒',
                  selected: listings.categoryFilter == null,
                  onTap: () => listings.filterByCategory(null),
                ),
                ...ListingType.values.map((t) => _CategoryChip(
                      label: t.label,
                      emoji: t.emoji,
                      selected: listings.categoryFilter == t,
                      onTap: () => listings.filterByCategory(t),
                    )),
              ],
            ),
          ),

          // ── Listing count ───────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${displayed.length} orodha zinapatikana',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.mid),
                ),
              ],
            ),
          ),

          // ── Listing cards ───────────────────────────────────────────────
          Expanded(
            child: displayed.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔍',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Hakuna orodha zilizopatikana.',
                          style: GoogleFonts.dmSans(
                              color: AppColors.mid, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 100),
                    itemCount: displayed.length,
                    itemBuilder: (context, i) => ListingCard(
                      listing: displayed[i],
                      onTazama: () =>
                          _openDetail(context, displayed[i]),
                      onOngea: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            contactId: displayed[i].seller.id,
                            contactName: displayed[i].seller.name,
                            contactRole: displayed[i].seller.role,
                            contactColorHex:
                                displayed[i].seller.colorHex,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.harvest,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Ongeza Orodha',
            style: GoogleFonts.dmSans(
                color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => _openAddListing(context),
      ),
    );
  }

  void _openAddListing(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddListingSheet(),
    );
  }

  void _openDetail(BuildContext context, ListingModel listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ListingDetailSheet(
        listing: listing,
        onOngea: () {
          Navigator.pop(context); // close sheet first
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                contactId: listing.seller.id,
                contactName: listing.seller.name,
                contactRole: listing.seller.role,
                contactColorHex: listing.seller.colorHex,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Category chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Text(emoji, style: const TextStyle(fontSize: 13)),
        label: Text(label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.ink,
            )),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.leaf,
        backgroundColor: AppColors.cream,
        checkmarkColor: Colors.white,
        side: BorderSide(
            color: selected
                ? AppColors.leaf
                : AppColors.mid.withValues(alpha: 0.3)),
        padding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
    );
  }
}

// ─── Listing card ──────────────────────────────────────────────────────────────

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTazama;
  final VoidCallback onOngea;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTazama,
    required this.onOngea,
  });

  @override
  Widget build(BuildContext context) {
    final sellerColor = _hexColor(listing.seller.colorHex);
    final badgeColor = _hexColor(listing.badgeColorHex);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShambaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Emoji container
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: sellerColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(listing.emoji,
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      if (listing.badgeText.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            listing.badgeText,
                            style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: badgeColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      // Title
                      Text(
                        listing.title,
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.ink,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Seller row
            Row(
              children: [
                UserAvatarCircle(
                    name: listing.seller.name,
                    role: listing.seller.role,
                    size: 24),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    listing.seller.name,
                    style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.mid,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                RoleChip(listing.seller.role, fontSize: 10),
              ],
            ),

            const SizedBox(height: 10),

            // Price + location + quantity row
            Row(
              children: [
                Text(
                  _tzs(listing.price),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.harvest,
                  ),
                ),
                Text(
                  ' / ${listing.unit}',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.mid),
                ),
                const Spacer(),
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.mid),
                Text(
                  listing.location,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.mid),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Text(
              'Kiasi: ${listing.quantityAvailable} ${listing.unit}',
              style: GoogleFonts.dmSans(
                  fontSize: 11, color: AppColors.mid),
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTazama,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.leaf,
                      side: const BorderSide(color: AppColors.leaf),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text('Tazama',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onOngea,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.leaf,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text('💬 Ongea',
                        style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Listing Bottom Sheet ──────────────────────────────────────────────────

class AddListingSheet extends StatefulWidget {
  const AddListingSheet({super.key});

  @override
  State<AddListingSheet> createState() => _AddListingSheetState();
}

class _AddListingSheetState extends State<AddListingSheet> {
  ListingType? _type;
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _unit = 'kg';
  String _location = 'Dar es Salaam';
  bool _loading = false;

  static const _units = [
    'kg', 'lita', 'pakiti', 'gunia', 'kipande',
    'ekari', 'safari', 'mwezi', 'tani', 'debe'
  ];

  static const _locations = [
    'Dar es Salaam', 'Arusha', 'Mbeya', 'Morogoro', 'Dodoma',
    'Tanga', 'Mwanza', 'Kilimanjaro', 'Pwani', 'Singida',
    'Tabora', 'Lindi', 'Mtwara', 'Ruvuma', 'Iringa',
    'Kagera', 'Kigoma', 'Mara', 'Shinyanga', 'Chalinze, Pwani',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_type == null ||
        _titleCtrl.text.trim().isEmpty ||
        _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jaza aina, jina, na bei kwanza.')),
      );
      return;
    }

    setState(() => _loading = true);

    final auth = context.read<AuthProvider>();
    final listingProv = context.read<ListingProvider>();
    final user = auth.currentUser!;

    final listing = ListingModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _type!,
      emoji: _type!.emoji,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: int.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0,
      unit: _unit,
      quantityAvailable:
          int.tryParse(_qtyCtrl.text) ?? 1,
      location: _location,
      createdAt: DateTime.now(),
      seller: SellerInfo(
        id: user.id,
        name: user.displayName,
        role: user.role,
        colorHex: user.role.colorHex,
      ),
      badgeText: 'Mpya',
      badgeColorHex: '#2E7D32',
    );

    await listingProv.addListing(listing);
    await auth.incrementListingCount();

    setState(() => _loading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Orodha "${listing.title}" imeongezwa!',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: AppColors.leaf,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mid.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Ongeza Orodha Mpya',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.soil)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  // Type selector
                  Text('Chagua Aina ya Orodha',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          color: AppColors.soil)),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.4,
                    children: ListingType.values.map((t) {
                      final sel = _type == t;
                      return GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.leaf
                                : AppColors.cream,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? AppColors.leaf
                                  : AppColors.mid
                                      .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(t.emoji,
                                  style: const TextStyle(
                                      fontSize: 22)),
                              const SizedBox(height: 4),
                              Text(t.label,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : AppColors.ink,
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // Title
                  _label('Jina la Bidhaa'),
                  _field(_titleCtrl, 'Mfano: Mahindi Daraja A'),

                  // Price
                  _label('Bei (TZS)'),
                  _field(_priceCtrl, 'Mfano: 3200',
                      type: TextInputType.number),

                  // Unit + Quantity row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _label('Kitengo'),
                            DropdownButtonFormField<String>(
                              initialValue: _unit,
                              decoration: _inputDecor(),
                              items: _units
                                  .map((u) => DropdownMenuItem(
                                      value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _unit = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _label('Kiasi Kilichopo'),
                            _field(_qtyCtrl, 'Mfano: 500',
                                type: TextInputType.number),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Location
                  _label('Mahali'),
                  DropdownButtonFormField<String>(
                    initialValue: _location,
                    decoration: _inputDecor(),
                    items: _locations
                        .map((l) =>
                            DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _location = v!),
                  ),
                  const SizedBox(height: 14),

                  // Description
                  _label('Maelezo'),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: _inputDecor().copyWith(
                      hintText:
                          'Elezea bidhaa yako, ubora wake, na masharti...',
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.harvest,
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Chapisha Orodha',
                            style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 14),
        child: Text(text,
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.soil)),
      );

  Widget _field(TextEditingController ctrl, String hint,
          {TextInputType type = TextInputType.text}) =>
      TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: _inputDecor().copyWith(hintText: hint));

  InputDecoration _inputDecor() => InputDecoration(
        filled: true,
        fillColor: AppColors.cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.harvest, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ─── Listing Detail Bottom Sheet ───────────────────────────────────────────────

class ListingDetailSheet extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback? onOngea;
  const ListingDetailSheet({super.key, required this.listing, this.onOngea});

  @override
  Widget build(BuildContext context) {
    final sellerColor = _hexColor(listing.seller.colorHex);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 0),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.mid.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Large emoji header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: sellerColor.withValues(alpha: 0.08),
              ),
              child: Column(
                children: [
                  Text(listing.emoji,
                      style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 8),
                  if (listing.badgeText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: sellerColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(listing.badgeText,
                          style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  // Title
                  Text(
                    listing.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.soil,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Imetumwa: ${_fmtDate(listing.createdAt)}',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.mid),
                  ),

                  const SizedBox(height: 16),

                  // Seller info row
                  ShambaCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        UserAvatarCircle(
                          name: listing.seller.name,
                          role: listing.seller.role,
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(listing.seller.name,
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.ink)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  RoleChip(listing.seller.role,
                                      fontSize: 10),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.location_on_outlined,
                                      size: 12, color: AppColors.mid),
                                  Text(listing.location,
                                      style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          color: AppColors.mid)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            const Icon(Icons.star,
                                color: AppColors.sun, size: 16),
                            Text('4.5',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Price / quantity / location info card
                  ShambaCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.attach_money,
                          label: 'Bei',
                          value:
                              '${_tzs(listing.price)} / ${listing.unit}',
                          valueColor: AppColors.harvest,
                          bold: true,
                        ),
                        const Divider(height: 16),
                        _InfoRow(
                          icon: Icons.inventory_2_outlined,
                          label: 'Kiasi',
                          value:
                              '${listing.quantityAvailable} ${listing.unit}',
                        ),
                        const Divider(height: 16),
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Mahali',
                          value: listing.location,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description
                  if (listing.description.isNotEmpty) ...[
                    Text('Maelezo',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.soil)),
                    const SizedBox(height: 8),
                    ShambaCard(
                      child: Text(listing.description,
                          style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: AppColors.ink,
                              height: 1.6)),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Primary: Ongea button
                  ElevatedButton(
                    onPressed: onOngea ?? () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sellerColor,
                      padding:
                          const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      '💬 Ongea na ${listing.seller.name.split(' ').first}',
                      style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Secondary: close
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.mid,
                      side: BorderSide(
                          color: AppColors.mid.withValues(alpha: 0.3)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Funga',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.mid)),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// One row in the detail info card
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mid),
        const SizedBox(width: 8),
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.mid)),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight:
                bold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }
}
