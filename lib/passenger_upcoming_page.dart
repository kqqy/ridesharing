import 'package:flutter/material.dart';
import 'trip_model.dart';
import 'passenger_upcoming_widgets.dart'; // 引入 UI
import 'passenger_widgets.dart'; // 為了使用 PassengerTripDetailsDialog
import 'chat_page.dart'; // 引入聊天室
import 'active_trip_page.dart'; // [修正] 引入更名後的行程進行中頁面

class PassengerUpcomingPage extends StatefulWidget {
  const PassengerUpcomingPage({super.key});

  @override
  State<PassengerUpcomingPage> createState() => _PassengerUpcomingPageState();
}

class _PassengerUpcomingPageState extends State<PassengerUpcomingPage> {
  // 假資料
  final List<Trip> _upcomingTrips = [
    Trip(origin: '台北車站', destination: '市政府', time: '2025-12-06 14:30', seats: '1/3', note: '無'),
    Trip(origin: '新竹科學園區', destination: '桃園高鐵站', time: '2025-12-07 08:00', seats: '2/4', note: '希望乘客不要吃東西'),
  ];

  // 處理取消/離開：交換按鈕位置 (確定在左，取消在右)
  void _handleCancelTrip(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('⚠️ 退出警告', style: TextStyle(color: Colors.red)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('若在六小時內退出，', style: TextStyle(fontSize: 16)),
            SizedBox(height: 5),
            Text('將會有放鳥紀錄！', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        actions: [
          // 1. 確定 (左)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('確定'),
          ),
          // 2. 取消 (右)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
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

  // 處理出發
  void _handleDepartTrip(Trip trip) {
    print('使用者在獨立頁面點擊出發：${trip.destination} (靜默模式)');
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
    return PassengerUpcomingBody(
      upcomingTrips: _upcomingTrips,
      onCancelTrip: _handleCancelTrip,
      onChatTrip: _handleChatTrip,
      onDetailTap: _handleTripDetail,
      
      // [修正] 修改出發邏輯：彈出點名視窗，確定後跳轉至 ActiveTripPage
      onDepartTrip: (trip) {
        final List<String> members = ['我 (司機)', '乘客 A', '乘客 B'];

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PassengerManifestDialog(
            members: members,
            onConfirm: () {
              Navigator.pop(context); // 關閉 Dialog
              
              // 跳轉到新的 ActiveTripPage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ActiveTripPage()),
              );
            },
          ),
        );
      },
    );
  }
}