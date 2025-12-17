// 這是用來定義「行程」長什麼樣子的檔案
class Trip {
  final String id;           // 行程 ID
  final String origin;       // 出發地
  final String destination;  // 目的地
  final DateTime departTime; // 出發時間
  final int seatsTotal;      // 總座位
  final int seatsLeft;       // 剩餘座位
  final String status;       // open / started / finished
  final String note;         // 備註

  Trip({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departTime,
    required this.seatsTotal,
    required this.seatsLeft,
    required this.status,
    required this.note,
  });

  /// ⭐ 從 Supabase 回傳的 Map 建立 Trip
  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      origin: map['origin'] as String,
      destination: map['destination'] as String,
      departTime: DateTime.parse(map['depart_time']),
      seatsTotal: map['seats_total'] as int,
      seatsLeft: map['seats_left'] as int,
      status: map['status'] as String,
      note: map['note'] ?? '',
    );
  }

  /// UI 用顯示字串（你原本的 seats）
  String get seatsText => '$seatsLeft/$seatsTotal';

  /// UI 用顯示時間
  String get timeText =>
      '${departTime.year}-${departTime.month.toString().padLeft(2, '0')}-${departTime.day.toString().padLeft(2, '0')} '
      '${departTime.hour.toString().padLeft(2, '0')}:${departTime.minute.toString().padLeft(2, '0')}';
}
