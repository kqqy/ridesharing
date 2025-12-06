import 'package:flutter/material.dart';
import 'trip_model.dart';
import 'passenger_upcoming_widgets.dart'; // 引入 UI
import 'passenger_widgets.dart'; // 為了使用 PassengerTripCard
import 'chat_page.dart'; // 引入聊天室

class PassengerUpcomingPage extends StatefulWidget {
  const PassengerUpcomingPage({super.key});

  @override
  State<PassengerUpcomingPage> createState() => _PassengerUpcomingPageState();
}

class _PassengerUpcomingPageState extends State<PassengerUpcomingPage> {
  // 假資料：這裡定義即將出發的行程
  final List<Trip> _upcomingTrips = [
    Trip(origin: '台北車站', destination: '市政府', time: '2025-12-06 14:30', seats: '1/3', note: '無'),
    Trip(origin: '新竹科學園區', destination: '桃園高鐵站', time: '2025-12-07 08:00', seats: '2/4', note: '希望乘客不要吃東西'),
  ];

  // 處理取消/離開 (靜默模式)
  void _handleCancelTrip(Trip trip) {
    print('使用者在獨立頁面點擊取消/離開：${trip.destination} (靜默模式)');
  }

  // 處理聊天室
  void _handleChatTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  // 處理出發 (靜默模式)
  void _handleDepartTrip(Trip trip) {
    print('使用者在獨立頁面點擊出發：${trip.destination} (靜默模式)');
  }

  // [新增/移動] 處理詳細資訊 (Logic moved from passenger_home.dart)
  void _handleTripDetail(Trip trip) {
    // 假資料：為詳細視窗提供成員與評分資料
    final List<Map<String, dynamic>> fakeMembers = [
      {'name': '王大明', 'role': '司機', 'rating': 4.9},
      {'name': '乘客 A', 'role': '乘客', 'rating': 5.0},
    ];

    showDialog(
      context: context,
      // [重點] 現在 PassengerTripDetailsDialog 是從 passenger_upcoming_widgets.dart 引入
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
      onDepartTrip: _handleDepartTrip,
    );
  }
}