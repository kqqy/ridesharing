// 這是用來定義「行程」長什麼樣子的檔案
class Trip {
  final String origin;      // 出發地
  final String destination; // 目的地
  final String time;        // 出發時間
  final String seats;       // 座位數
  final String note;        // 備註

  Trip({
    required this.origin,
    required this.destination,
    required this.time,
    required this.seats,
    required this.note,
  });
}