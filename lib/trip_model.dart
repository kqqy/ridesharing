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
  final List<Map<String, dynamic>> tripMembers; // 行程成員

  Trip({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departTime,
    required this.seatsTotal,
    required this.seatsLeft,
    required this.status,
    required this.note,
    required this.tripMembers,
  });

  /// ⭐ 從 Supabase 回傳的 Map 建立 Trip
  factory Trip.fromMap(Map<String, dynamic> map) {
    // 確保解析時處理 UTC 字串並轉為本地時區
    String timeStr = map['depart_time'];
    // 如果字串沒有時區資訊（無 Z 且無 +），強制視為 UTC
    if (!timeStr.endsWith('Z') && !timeStr.contains('+')) {
      timeStr += 'Z';
    }
    
    final dt = DateTime.parse(timeStr);
    return Trip(
      id: map['id'] as String,
      origin: map['origin'] as String,
      destination: map['destination'] as String,
      departTime: dt.toLocal(), // 強制轉為手機當地時間
      seatsTotal: map['seats_total'] as int,
      seatsLeft: map['seats_left'] as int,
      status: map['status'] as String,
      note: map['note'] ?? '',
      tripMembers: (map['trip_members'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }

  /// UI 用顯示字串（顯示：已佔用/總座位）
  String get seatsText => '${seatsTotal - seatsLeft}/$seatsTotal';

  /// UI 用顯示時間
  String get timeText =>
      '${departTime.year}-${departTime.month.toString().padLeft(2, '0')}-${departTime.day.toString().padLeft(2, '0')} '
      '${departTime.hour.toString().padLeft(2, '0')}:${departTime.minute.toString().padLeft(2, '0')}';
}
