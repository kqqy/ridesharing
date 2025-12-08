import 'package:flutter/material.dart';
import 'trip_model.dart';
import 'upcoming_widgets.dart'; // 引入 UI
import 'chat_page.dart';        // 引入聊天室
import 'active_trip_page.dart'; // 引入行程進行中頁面

class UpcomingPage extends StatefulWidget {
  final bool isDriver; 

  const UpcomingPage({super.key, required this.isDriver});

  @override
  State<UpcomingPage> createState() => _UpcomingPageState();
}

class _UpcomingPageState extends State<UpcomingPage> {
  // 假資料
  final List<Trip> _upcomingTrips = [
    Trip(origin: '台北車站', destination: '市政府', time: '2025-12-06 14:30', seats: '1/3', note: '無'),
    Trip(origin: '新竹科學園區', destination: '桃園高鐵站', time: '2025-12-07 08:00', seats: '2/4', note: '希望乘客不要吃東西'),
  ];

  // 處理取消/離開
  void _handleCancelTrip(Trip trip) {
    String title = widget.isDriver ? '確定取消行程？' : '⚠️ 退出警告';
    Widget content = widget.isDriver 
        ? const Text('取消後將通知所有乘客，且無法復原。')
        : const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('若在六小時內退出，', style: TextStyle(fontSize: 16)),
              SizedBox(height: 5),
              Text('將會有放鳥紀錄！', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: content,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('確定'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
        ],
        actionsAlignment: MainAxisAlignment.end,
      ),
    );
  }

  // 處理聊天室
  void _handleChatTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  // 處理出發 (乘客端)
  void _handleDepartTrip(Trip trip) {
    // 1. 準備假成員資料 (顯示在點名視窗中)
    final List<String> tripMembers = ['司機', '我 (乘客)', '乘客 B'];

    // 2. 顯示乘客專用的點名視窗
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PassengerManifestDialog(
        members: tripMembers,
        onConfirm: () {
          Navigator.pop(context); // 關閉 Dialog
          // 3. 跳轉到行程進行中頁面
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ActiveTripPage()),
          );
        },
      ),
    );
  }

  // 處理詳細資訊
  void _handleTripDetail(Trip trip) {
    final List<Map<String, dynamic>> fakeMembers = [
      {'name': '王大明', 'role': '司機', 'rating': 4.9},
      {'name': '乘客 A', 'role': '乘客', 'rating': 5.0},
    ];

    showDialog(
      context: context,
      builder: (context) => PassengerTripDetailsDialog(
        trip: trip,
        members: fakeMembers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UpcomingBody(
      isDriver: widget.isDriver, 
      upcomingTrips: _upcomingTrips,
      onCancelTrip: _handleCancelTrip,
      onChatTrip: _handleChatTrip,
      onDetailTap: _handleTripDetail,
      // 乘客端：傳入出發函式；司機端：null
      onDepartTrip: widget.isDriver ? null : _handleDepartTrip,
    );
  }
}