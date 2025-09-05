import 'package:flutter/material.dart';
import '../services/parking/parking_api.dart';

class RatePlanCreatePage extends StatefulWidget {
  final ParkingApi api;
  final int? initialLotId;
  const RatePlanCreatePage({super.key, required this.api, this.initialLotId});

  @override
  State<RatePlanCreatePage> createState() => _RatePlanCreatePageState();
}

class _RatePlanCreatePageState extends State<RatePlanCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _adCtrl = TextEditingController();
  final _saatlikCtrl = TextEditingController();
  final _gunlukCtrl = TextEditingController();

  bool _saving = false;
  bool _loadingLots = false;
  List<Map<String, dynamic>> _lots = [];
  Map<String, dynamic>? _selectedLot;

  @override
  void initState() {
    super.initState();
    _loadLots();
  }

  @override
  void dispose() {
    _adCtrl.dispose();
    _saatlikCtrl.dispose();
    _gunlukCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLots() async {
    setState(() => _loadingLots = true);
    try {
      final lots = await widget.api.listLots();
      setState(() {
        _lots = lots;
        if (_lots.isNotEmpty) {
          if (widget.initialLotId != null) {
            _selectedLot = _lots.firstWhere(
              (e) => e['id'] == widget.initialLotId,
              orElse: () => _lots.first,
            );
          } else {
            _selectedLot = _lots.first;
          }
        }
      });
    } catch (e) {
      _snack('Otoparklar alınamadı: $e');
    } finally {
      setState(() => _loadingLots = false);
    }
  }

  String? _moneyValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final rx = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!rx.hasMatch(v.trim())) return '75.00 gibi bir format kullanın';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLot == null) {
      _snack('Lütfen otopark seçin.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.api.createRatePlan(
        lot: _selectedLot!['id'] as int,
        ad: _adCtrl.text.trim(),
        saatlikUcret: _saatlikCtrl.text.trim(),
        gunlukTavan:
            _gunlukCtrl.text.trim().isEmpty ? null : _gunlukCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tarife oluşturuldu.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Tarife')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (_loadingLots) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedLot,
              items:
                  _lots
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text('${l['ad']} (${l['tip']})'),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedLot = v),
              decoration: const InputDecoration(
                labelText: 'Otopark',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _adCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ad (örn. Standart)',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (v) =>
                            (v == null || v.trim().isEmpty) ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _saatlikCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Saatlik Ücret (örn. 75.00)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Zorunlu';
                      return _moneyValidator(v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gunlukCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Günlük Tavan (opsiyonel, 400.00)',
                      border: OutlineInputBorder(),
                    ),
                    validator: _moneyValidator,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon:
                          _saving
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.save),
                      label: const Text('Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
