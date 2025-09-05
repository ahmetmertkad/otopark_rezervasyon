class RatePlan {
  final int id;
  final int lot; // lot id
  final String ad;
  final String saatlikUcret; // backend Decimal genelde string döner
  final String? gunlukTavan;

  RatePlan({
    required this.id,
    required this.lot,
    required this.ad,
    required this.saatlikUcret,
    this.gunlukTavan,
  });

  factory RatePlan.fromJson(Map<String, dynamic> j) => RatePlan(
    id: j['id'] as int,
    lot: j['lot'] as int,
    ad: j['ad'] as String,
    saatlikUcret: j['saatlik_ucret']?.toString() ?? '0.00',
    gunlukTavan: j['gunluk_tavan']?.toString(),
  );
}
