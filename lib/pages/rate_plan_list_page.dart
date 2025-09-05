import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/parking/parking_api.dart';
import 'rate_plan_create_page.dart';

class RatePlanListPage extends StatefulWidget {
  final ParkingApi api;
  const RatePlanListPage({super.key, required this.api});

  @override
  State<RatePlanListPage> createState() => _RatePlanListPageState();
}

class _RatePlanListPageState extends State<RatePlanListPage> {
  bool _loadingLots = false;
  bool _loadingPlans = false;
  List<Map<String, dynamic>> _lots = [];
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _selectedLot;

  @override
  void initState() {
    super.initState();
    _fetchLots();
  }

  Future<void> _fetchLots() async {
    setState(() => _loadingLots = true);
    try {
      final lots = await widget.api.listLots();
      setState(() {
        _lots = lots;
        if (_lots.isNotEmpty) {
          _selectedLot = _lots.first;
          _fetchPlans();
        }
      });
    } catch (e) {
      _snack('Otoparklar yüklenemedi: $e');
    } finally {
      setState(() => _loadingLots = false);
    }
  }

  Future<void> _fetchPlans() async {
    if (_selectedLot == null) return;
    setState(() => _loadingPlans = true);
    try {
      final plans = await widget.api.listRatePlans(
        lotId: _selectedLot!['id'] as int,
      );
      setState(() => _plans = plans);
    } catch (e) {
      _snack('Tarifeler yüklenemedi: $e');
    } finally {
      setState(() => _loadingPlans = false);
    }
  }

  Future<void> _openCreate() async {
    if (_selectedLot == null) {
      _snack('Önce otopark seçin.');
      return;
    }
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (_) => RatePlanCreatePage(
              api: widget.api,
              initialLotId: _selectedLot!['id'] as int,
            ),
      ),
    );
    if (created == true) {
      _fetchPlans();
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tarifeler')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Tarife'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child:
                _loadingLots
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<Map<String, dynamic>>(
                      value: _selectedLot,
                      decoration: const InputDecoration(
                        labelText: 'Otopark seç',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          _lots
                              .map(
                                (l) => DropdownMenuItem(
                                  value: l,
                                  child: Text('${l['ad']} (${l['tip']})'),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        setState(() => _selectedLot = v);
                        _fetchPlans();
                      },
                    ),
          ),
          Expanded(
            child:
                _loadingPlans
                    ? const Center(child: CircularProgressIndicator())
                    : _plans.isEmpty
                    ? const Center(child: Text('Bu otoparka ait tarife yok.'))
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _plans.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final p = _plans[i];
                        return Card(
                          elevation: 2,
                          child: ListTile(
                            leading: const Icon(Icons.price_change),
                            title: Text(
                              p['ad']?.toString() ?? '-',
                              style: theme.textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              'Saatlik: ${p['saatlik_ucret']} ₺'
                              '${p['gunluk_tavan'] != null ? ' • Günlük tavan: ${p['gunluk_tavan']} ₺' : ''}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'delete') {
                                  try {
                                    await widget.api.deleteRatePlan(
                                      p['id'] as int,
                                    );
                                    _snack('Silindi');
                                    _fetchPlans();
                                  } catch (e) {
                                    _snack('Silme hatası: $e');
                                  }
                                }
                              },
                              itemBuilder:
                                  (_) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Sil'),
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
