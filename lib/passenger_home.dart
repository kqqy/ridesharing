import 'package:flutter/material.dart';
import 'package:ridesharing/chat_widgets.dart';
import 'passenger_widgets.dart'; 
import 'trip_model.dart'; 
import 'passenger_create_trip_page.dart'; 
import 'upcoming_page.dart'; 
import 'upcoming_widgets.dart'; 
import 'history_page.dart'; 

class PassengerHome extends StatefulWidget {
  final Color themeColor;

  const PassengerHome({super.key, required this.themeColor});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  bool _showManageMenu = false;

  final List<Trip> _exploreTrips = [
    Trip(origin: '台中逢甲大學', destination: '台中高鐵站', time: '2025-12-06 18:00', seats: '3/4', note: '順路載人'),
     Trip(origin: '台南火車站', destination: '高雄巨蛋', time: '2025-12-08 10:00', seats: '2/4', note: '有寵物'),
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
        MaterialPageRoute(builder: (context) => const UpcomingPage(isDriver: false)),
      );
    } else if (type == '歷史行程與統計') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistoryPage()),
      );
    }
  }
  
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

  void _handleJoinTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatBody(
          tripMembers: const [],   // 先空資料，之後再接 Supabase
          onMemberListTap: () {
            // 之後可以打開成員列表
          },
        ),
      ),
    );
  }

  // 建立行程
  void _handleCreateTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PassengerCreateTripPage()),
    );
    if (result == true) {
      // 這裡可以處理新增成功後的邏輯，例如刷新列表
      // 目前保持靜默
    }
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = AppBar().preferredSize.height;

    // [修改] 使用 Scaffold 包裹，以便使用標準的 FloatingActionButton
    return Scaffold(
      backgroundColor: Colors.white,
      // [新增] 右下角懸浮按鈕 (建立行程)
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreateTrip,
        backgroundColor: Colors.blue,
        shape: const CircleBorder(), // 圓形
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: Stack(
        children: [
          // 底層：主頁面內容
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

          // 上層：右上角選單 (如果 _showManageMenu 為 true 則顯示)
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
      ),
    );
  }
}