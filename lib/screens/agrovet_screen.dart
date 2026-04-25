import 'package:flutter/material.dart';
import '../services/data_sync_service.dart';

const List<String> kRegions = [
  'Morogoro', 'Kilosa', 'Pwani', 'Arusha',
  'Iringa', 'Mbeya', 'Dodoma', 'Dar es Salaam',
  'Mwanza', 'Tanga', 'Kagera', 'Mara',
];

class AgrovetScreen extends StatefulWidget {
  const AgrovetScreen({super.key});

  @override
  State<AgrovetScreen> createState() => _AgrovetScreenState();
}

class _AgrovetScreenState extends State<AgrovetScreen> {
  String _selectedRegion = 'Morogoro';
  List<Map<String, dynamic>> _agrovets = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAgrovets();
  }

  Future<void> _loadAgrovets() async {
    setState(() => _loading = true);

    final results =
        await DataSyncService.fetchAgrovets(_selectedRegion);

    setState(() {
      _agrovets = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maduka ya Dawa za Kilimo'),
      ),
      body: Column(
        children: [
          // Source banner
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFE8F5E9),
            child: const Row(
              children: [
                Icon(Icons.store, color: Color(0xFF1A5C2E), size: 16),
                SizedBox(width: 6),
                Text(
                  'Maduka yaliyohakikishwa Tanzania',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF1A5C2E)),
                ),
              ],
            ),
          ),

          // Region selector
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedRegion,
              decoration: InputDecoration(
                labelText: 'Chagua Mkoa',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: kRegions
                  .map((r) =>
                      DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedRegion = val);
                  _loadAgrovets();
                }
              },
            ),
          ),

          // List of agrovets
          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: Color(0xFF1A5C2E)),
                        SizedBox(height: 12),
                        Text('Inatafuta maduka...',
                            style:
                                TextStyle(color: Color(0xFF9E9E9E))),
                      ],
                    ),
                  )
                : _agrovets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.store_mall_directory,
                                size: 60,
                                color: Color(0xFF9E9E9E)),
                            const SizedBox(height: 12),
                            const Text(
                              'Hakuna maduka yaliyopatikana.',
                              style: TextStyle(
                                  color: Color(0xFF9E9E9E)),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('Jaribu Tena'),
                              onPressed: _loadAgrovets,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12),
                        itemCount: _agrovets.length,
                        itemBuilder: (context, index) {
                          final shop = _agrovets[index];
                          return Card(
                            margin:
                                const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // Store icon
                                  CircleAvatar(
                                    backgroundColor:
                                        const Color(0xFF1A5C2E),
                                    child: const Icon(Icons.store,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),

                                  // Shop details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                shop['shop_name'] ??
                                                    'Duka',
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            if (shop['verified'] ==
                                                true)
                                              const Icon(
                                                  Icons.verified,
                                                  color: Color(
                                                      0xFF1A5C2E),
                                                  size: 16),
                                          ],
                                        ),
                                        if ((shop['area'] ?? '')
                                            .isNotEmpty)
                                          Text(
                                            '${shop['area']}, ${shop['region'] ?? _selectedRegion}',
                                            style: const TextStyle(
                                                color: Color(
                                                    0xFF9E9E9E),
                                                fontSize: 13),
                                          ),
                                        if ((shop['products'] ?? '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            shop['products'],
                                            style: const TextStyle(
                                                fontSize: 12),
                                          ),
                                        ],
                                        if ((shop['opening_hours'] ??
                                                '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                  Icons.access_time,
                                                  size: 13,
                                                  color: Color(
                                                      0xFF9E9E9E)),
                                              const SizedBox(
                                                  width: 4),
                                              Text(
                                                shop['opening_hours'],
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(
                                                        0xFF9E9E9E)),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if ((shop['phone'] ?? '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone,
                                                  size: 14,
                                                  color: Color(
                                                      0xFF1A5C2E)),
                                              const SizedBox(
                                                  width: 4),
                                              Text(
                                                shop['phone'],
                                                style: const TextStyle(
                                                  color: Color(
                                                      0xFF1A5C2E),
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
