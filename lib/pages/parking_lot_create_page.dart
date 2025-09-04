// lib/pages/parking_lot_create_page.dart
import 'package:flutter/material.dart';
import '../services/parking/parking_api.dart';

class ParkingLotCreatePage extends StatefulWidget {
  final ParkingApi api;
  final VoidCallback? onCreated; // başarı sonrası geri dönüş
  const ParkingLotCreatePage({super.key, required this.api, this.onCreated});

  @override
  State<ParkingLotCreatePage> createState() => _ParkingLotCreatePageState();
}

class _ParkingLotCreatePageState extends State<ParkingLotCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _ad = TextEditingController();
  final _konum = TextEditingController();
  final _kapasite = TextEditingController(text: '10');

  String _tip = 'acik';
  bool _aktif = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ad.dispose();
    _konum.dispose();
    _kapasite.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.api.createLot(
        ad: _ad.text.trim(),
        tip: _tip,
        konum: _konum.text.trim().isEmpty ? null : _konum.text.trim(),
        kapasite: int.parse(_kapasite.text.trim()),
        aktif: _aktif,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Otopark eklendi')));
      widget.onCreated?.call();
      Navigator.maybePop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    const tips = [
      DropdownMenuItem(value: 'acik', child: Text('Açık')),
      DropdownMenuItem(value: 'kapali', child: Text('Kapalı')),
      DropdownMenuItem(value: 'vip', child: Text('VIP')),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Otopark Ekle')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _ad,
                        decoration: const InputDecoration(
                          labelText: 'Otopark Adı',
                          prefixIcon: Icon(Icons.local_parking_outlined),
                        ),
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Zorunlu'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _tip,
                        items: tips,
                        decoration: const InputDecoration(
                          labelText: 'Tip',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        onChanged: (v) => setState(() => _tip = v ?? 'acik'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _konum,
                        decoration: const InputDecoration(
                          labelText: 'Konum (isteğe bağlı)',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _kapasite,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Kapasite',
                          prefixIcon: Icon(Icons.reduce_capacity_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Zorunlu';
                          final n = int.tryParse(v);
                          if (n == null || n < 1) return '1 veya üstü olmalı';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _aktif,
                        onChanged: (v) => setState(() => _aktif = v),
                        title: const Text('Aktif'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _busy ? null : _submit,
                          icon:
                              _busy
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.save_outlined),
                          label: Text(_busy ? 'Kaydediliyor...' : 'Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
