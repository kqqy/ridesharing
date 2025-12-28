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
  List<Trip> _exploreTrips = [];

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadExploreTrips();
  }

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

  // ✅ 簡化：直接使用會自動載入成員的 Dialog
  void _handleTripDetail(Trip trip) {
    showDialog(
      context: context,
      builder: (_) => PassengerTripDetailsDialog(
        trip: trip,  // ✅ 只傳 trip，Dialog 會自己載入成員
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
      debugPrint('✅ 開始申請加入行程，trip_id: ${trip.id}, user_id: ${user.id}');

      // 1️⃣ 檢查是否已經是成員
      final existMember = await supabase
          .from('trip_members')
          .select('id')
          .eq('trip_id', trip.id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existMember != null) {
        debugPrint('⚠️ 用戶已經在此行程中');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('你已經是此行程的成員')),
          );
        }
        return;
      }

      // 2️⃣ 檢查是否已經發送過申請
      final existRequest = await supabase
          .from('join_requests')
          .select('trip_id')
          .eq('trip_id', trip.id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existRequest != null) {
        debugPrint('⚠️ 申請已發送，等待審核');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('申請已發送，請等待創建者審核')),
          );
        }
        return;
      }

      // 3️⃣ 發送加入申請
      debugPrint('✅ 寫入 join_requests...');
      await supabase.from('join_requests').insert({
        'trip_id': trip.id,
        'user_id': user.id,
      });

      debugPrint('✅ 成功發送加入申請');

      // 4️⃣ 成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已發送加入申請，請等待創建者審核'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ 發送申請失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發送申請失敗: $e')),
        );
      }
    }
  }

  void _handleCreateTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PassengerCreateTripPage(),
      ),
    );

    if (result == true) {
      _loadExploreTrips();
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