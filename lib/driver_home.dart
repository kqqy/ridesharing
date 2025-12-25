import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'trip_model.dart';
import 'driver_widgets.dart';
import 'chat_page.dart';
import 'upcoming_page.dart';
import 'history_page.dart';
import 'upcoming_widgets.dart';

final supabase = Supabase.instance.client;

class DriverHome extends StatefulWidget {
  final Color themeColor;

  const DriverHome({super.key, required this.themeColor});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool _showManageMenu = false;

  Trip? _currentActiveTrip;

  // ✅ 改成「真資料」
  List<Trip> _exploreTrips = [];
  bool _loadingExplore = true;

  @override
  void initState() {
    super.initState();
    _fetchExploreTrips();
  }

  // ===============================
  // 從 Supabase 撈 Explore（open 行程）
  // ===============================
  Future<void> _fetchExploreTrips() async {
    try {
      final data = await supabase
          .from('trips')
          .select()
          .eq('status', 'open')
          .order('depart_time');

      final trips = (data as List).map<Trip>((e) {
        return Trip(
          id: e['id'].toString(), // ✅ DB uuid
          origin: e['origin'] ?? '',
          destination: e['destination'] ?? '',
          departTime: DateTime.parse(e['depart_time']),
          seatsTotal: e['seats_total'] ?? 0,
          seatsLeft: e['seats_left'] ?? 0,
          status: e['status'] ?? '',
          note: e['note'] ?? '',
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _exploreTrips = trips;
        _loadingExplore = false;
      });
    } catch (e) {
      debugPrint('fetch explore trips error: $e');
      if (!mounted) return;
      setState(() => _loadingExplore = false);
    }
  }

  void _closeAllDialogs() {
    if (_showManageMenu) {
      setState(() => _showManageMenu = false);
    }
  }

  // Explore：先只做 UI，不動 DB
  void _handleJoinTrip(Trip trip) {
    debugPrint('加入行程（之後接 trip_members）: ${trip.id}');
  }

  void _handleExploreDetail(Trip trip) {
    final List<Map<String, dynamic>> fakeMembers = [
      {'name': '發起人', 'role': '乘客', 'rating': 4.8},
    ];

    showDialog(
      context: context,
      builder: (context) => PassengerTripDetailsDialog(
        trip: trip,
        members: fakeMembers,
      ),
    );
  }

  void _handleMenuSelection(String value) {
    setState(() => _showManageMenu = false);

    if (value == '即將出發行程') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const UpcomingPage(isDriver: true),
        ),
      );
    } else if (value == '歷史行程與統計') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistoryPage()),
      );
    }
  }

  void _handleSOS() {
    showDialog(
      context: context,
      builder: (context) => const SOSCountdownDialog(),
    );
  }

  void _handleArrived() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認到達？'),
        content: const Text('這將結束目前的行程。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentActiveTrip = null);
              showDialog(
                context: context,
                builder: (context) => const DriverRatePassengerDialog(),
              );
            },
            child: const Text('確定到達'),
          ),
        ],
      ),
    );
  }

  // ✅ 聊天室：只允許「進行中的真行程」
  void _handleChat() {
    if (_currentActiveTrip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目前沒有進行中的行程')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(tripId: _currentActiveTrip!.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DriverHomeBody(
      themeColor: widget.themeColor,
      currentActiveTrip: _currentActiveTrip,
      isManageMenuVisible: _showManageMenu,
      exploreTrips: _exploreTrips,
      //isExploreLoading: _loadingExplore,
      onJoinTrip: _handleJoinTrip,
      onExploreDetail: _handleExploreDetail,
      onManageTap: () =>
          setState(() => _showManageMenu = !_showManageMenu),
      onMenuClose: _closeAllDialogs,
      onMenuSelect: _handleMenuSelection,
      onSOS: _handleSOS,
      onArrived: _handleArrived,
      onShare: () {},
      onChat: _handleChat,
    );
  }
}
