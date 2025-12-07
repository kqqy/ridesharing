import 'package:flutter/material.dart';
import 'passenger_widgets.dart'; 
import 'trip_model.dart'; 
import 'passenger_create_trip_page.dart'; 
import 'upcoming_page.dart'; 
import 'upcoming_widgets.dart'; 
import 'history_page.dart'; // 引入 HistoryPage

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
        // [修正] 移除 const，改為 HistoryPage()
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
    // 靜默
  }

  void _handleCreateTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PassengerCreateTripPage()),
    );
    if (result == true) {
      // 靜默
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