class ParkingLot {
  final int id;
  final String ad;
  final String tip; // acik | kapali | vip
  final String? konum;
  final int kapasite;
  final bool aktif;

  ParkingLot({
    required this.id,
    required this.ad,
    required this.tip,
    this.konum,
    required this.kapasite,
    required this.aktif,
  });

  factory ParkingLot.fromJson(Map<String, dynamic> j) => ParkingLot(
    id: j['id'] as int,
    ad: j['ad'] as String,
    tip: j['tip'] as String,
    konum: j['konum'] as String?,
    kapasite: j['kapasite'] as int,
    aktif: j['aktif'] as bool,
  );
}
