import 'package:flutter/material.dart';
import 'passenger_widgets.dart'; // 引入乘客的 UI 組件
import 'trip_model.dart'; // 引入資料結構
// import 'chat_page.dart'; // [修正] 移除未使用的引入
import 'passenger_create_trip_page.dart'; // 引入創建行程頁面
import 'passenger_upcoming_page.dart'; // 引入即將出發行程頁面
import 'passenger_upcoming_widgets.dart'; // [修正] 確保引入以使用 PassengerTripDetailsDialog
import 'passenger_history_page.dart'; // 引入歷史行程頁面

class PassengerHome extends StatefulWidget {
  final Color themeColor;

  const PassengerHome({super.key, required this.themeColor});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  bool _showManageMenu = false;

  // 探索行程 (首頁顯示的假資料)
  final List<Trip> _exploreTrips = [
    Trip(
      origin: '台中逢甲大學', 
      destination: '台中高鐵站', 
      time: '2025-12-06 18:00', 
      seats: '3/4', 
      note: '順路載人，歡迎共乘'
    ),
     Trip(
      origin: '台南火車站', 
      destination: '高雄巨蛋', 
      time: '2025-12-08 10:00', 
      seats: '2/4', 
      note: '目前車上有一隻寵物狗'
    ),
  ];

  void _closeMenu() {
    setState(() {
      _showManageMenu = false;
    });
  }

  void _handleManageTrip() {
    setState(() {
      _showManageMenu = !_showManageMenu; 
    });
  }

  void _handleMenuSelection(String type) {
    _closeMenu(); 
    if (type == '即將出發行程') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PassengerUpcomingPage()),
      );
    } else if (type == '歷史行程與統計') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PassengerHistoryPage()),
      );
    }
  }
  
  // 共用邏輯：查看詳細
  void _handleTripDetail(Trip trip) {
    final List<Map<String, dynamic>> fakeMembers = [
      {'name': '王司機', 'role': '司機', 'rating': 4.7},
      {'name': '乘客 B', 'role': '乘客', 'rating': 4.5},
    ];

    showDialog(
      context: context,
      builder: (context) => PassengerTripDetailsDialog(
        trip: trip,
        members: fakeMembers,
      ),
    );
  }

  // 處理「我要共乘」按鈕 (靜默模式)
  void _handleJoinTrip(Trip trip) {
    // 執行加入共乘邏輯
  }

  // 處理「創建行程」按鈕
  void _handleCreateTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PassengerCreateTripPage()),
    );

    if (result == true) {
      // 刷新列表
    }
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = AppBar().preferredSize.height;

    return Stack(
      children: [
        GestureDetector(
          onTap: _closeMenu,
          behavior: HitTestBehavior.translucent,
          child: PassengerHomeBody(
            themeColor: widget.themeColor,
            onManageTripTap: _handleManageTrip,
            exploreTrips: _exploreTrips, 
            onExploreDetail: _handleTripDetail, 
            onExploreJoin: _handleJoinTrip, 
            onCreateTrip: _handleCreateTrip, 
          ),
        ),

        if (_showManageMenu)
          Positioned(
            top: appBarHeight + 10, 
            right: 15,
            child: PassengerTripMenu(
              onUpcomingTap: () => _handleMenuSelection('即將出發行程'),
              onHistoryTap: () => _handleMenuSelection('歷史行程與統計'),
            ),
          ),
      ],
    );
  }
}