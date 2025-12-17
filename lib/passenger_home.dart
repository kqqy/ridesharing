import 'package:flutter/material.dart';
import 'package:ridesharing/chat_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// ⭐ 不再用寫死樣本
  List<Trip> _exploreTrips = [];

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadExploreTrips(); // ⭐ 一進頁面就從 DB 抓
  }

  /// ⭐ 從 Supabase 讀取探索行程
  Future<void> _loadExploreTrips() async {
    final data = await supabase
        .from('trips')
        .select()
        .eq('status', 'open')
        .order('depart_time');

    final trips = (data as List)
        .map((e) => Trip.fromMap(e))
        .toList();

    setState(() {
      _exploreTrips = trips;
    });
  }

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
        MaterialPageRoute(
          builder: (_) => const UpcomingPage(isDriver: false),
        ),
      );
    } else if (type == '歷史行程與統計') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryPage()),
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
      builder: (_) => PassengerTripDetailsDialog(
        trip: trip,
        members: fakeMembers,
      ),
    );
  }

  void _handleJoinTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatBody(
          tripMembers: const [],
          onMemberListTap: () {},
        ),
      ),
    );
  }

  /// ⭐ 建立行程 → 成功後重新抓資料
  void _handleCreateTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PassengerCreateTripPage(),
      ),
    );

    if (result == true) {
      _loadExploreTrips(); // ⭐ 關鍵
    }
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = AppBar().preferredSize.height;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreateTrip,
        backgroundColor: Colors.blue,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: Stack(
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
                onUpcomingTap: () =>
                    _handleMenuSelection('即將出發行程'),
                onHistoryTap: () =>
                    _handleMenuSelection('歷史行程與統計'),
              ),
            ),
        ],
      ),
    );
  }
}
