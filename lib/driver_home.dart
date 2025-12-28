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
          id: e['id'].toString(),
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

  void _handleJoinTrip(Trip trip) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入')),
      );
      return;
    }

    try {
      // 檢查是否已經是成員
      final existMember = await supabase
          .from('trip_members')
          .select('id')
          .eq('trip_id', trip.id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existMember != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('你已經是此行程的成員')),
          );
        }
        return;
      }

      // 檢查是否已經發送過申請
      final existRequest = await supabase
          .from('join_requests')
          .select('trip_id')
          .eq('trip_id', trip.id)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existRequest != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('申請已發送，請等待創建者審核')),
          );
        }
        return;
      }

      // 發送加入申請
      await supabase.from('join_requests').insert({
        'trip_id': trip.id,
        'user_id': user.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已發送加入申請，請等待創建者審核'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('發送申請失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發送申請失敗: $e')),
        );
      }
    }
  }

  // ✅ 簡化：直接使用會自動載入成員的 Dialog
  void _handleExploreDetail(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => PassengerTripDetailsDialog(
        trip: trip,  // ✅ 只傳 trip，Dialog 會自己載入成員
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