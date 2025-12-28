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
        .eq('status', 'open')  // ✅ 只顯示招募中
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

  void _handleJoinTrip(Trip trip) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入')),
      );
      return;
    }

    try {
      debugPrint('✅ 開始加入行程，trip_id: ${trip.id}, user_id: ${user.id}');

      // 1️⃣ 檢查是否已經加入過這個行程
      final exist = await supabase
          .from('trip_members')
          .select('id')
          .eq('trip_id', trip.id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (exist != null) {
        debugPrint('⚠️ 用戶已經在此行程中');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('你已經加入過此行程')),
        );
        return;
      }

      // 2️⃣ 加入行程
      debugPrint('✅ 寫入 trip_members...');
      await supabase.from('trip_members').insert({
        'trip_id': trip.id,
        'user_id': user.id,
        'role': 'passenger',  // ✅ 加上 role
        'join_time': DateTime.now().toIso8601String(),  // ✅ 加上 join_time
      });

      debugPrint('✅ 成功加入 trip_members');

      // 3️⃣ 成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已成功加入行程')),
        );
      }

    } catch (e) {
      debugPrint('❌ 加入行程失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法加入行程: $e')),
        );
      }
    }
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
