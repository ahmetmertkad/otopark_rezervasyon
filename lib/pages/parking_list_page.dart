import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/parking/parking_api.dart';

class ParkingListPage extends StatefulWidget {
  const ParkingListPage({super.key});

  @override
  State<ParkingListPage> createState() => _ParkingListPageState();
}

class _ParkingListPageState extends State<ParkingListPage> {
  late ParkingApi api;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _lots = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    api = context.read<ParkingApi>();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await api.listLots();
      setState(() => _lots = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Otoparklar')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : RefreshIndicator(
                onRefresh: _fetch,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _lots.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final it = _lots[i];
                    return ListTile(
                      leading: const Icon(Icons.local_parking),
                      title: Text(it['ad'] ?? '-'),
                      subtitle: Text(
                        'Tip: ${it['tip']} • Kapasite: ${it['kapasite']}',
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
