import 'package:flutter/material.dart';
import 'trip_model.dart';
import 'upcoming_widgets.dart'; // 引入 UI
import 'driver_widgets.dart';   // 引入司機的 DriverManifestDialog
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

  // 處理出發 (邏輯)
  void _handleDepartTrip(Trip trip) {
    // 這裡通常會呼叫 API，或顯示點名單
    // 為了範例，我們這裡暫時只做簡單跳轉，或者您可以復原之前的點名邏輯
    // 因為這是"通用"頁面，這裡假設乘客點擊出發可能是"我已上車"之類的意思，
    // 或是如果您的需求是乘客端按出發無效，可以在這裡不做任何事，但UI按鈕會顯示。
    
    // 如果您希望乘客端按出發是跳轉到 ActiveTripPage (模擬行程開始)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActiveTripPage()),
    );
  }

  // 處理詳細資訊
  void _handleTripDetail(Trip trip) {
    // 這裡的資料如果是真實的，應該從 API 獲取
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
      
      // [關鍵修改] 邏輯控制：
      // 如果是司機 -> 傳入 null (UI 就會隱藏按鈕)
      // 如果是乘客 -> 傳入 _handleDepartTrip (UI 就會顯示按鈕)
      onDepartTrip: widget.isDriver ? null : _handleDepartTrip,
    );
  }
}