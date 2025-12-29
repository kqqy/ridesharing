import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'trip_model.dart';
import 'driver_widgets.dart';
import 'chat_page.dart';
import 'upcoming_page.dart';
import 'history_page.dart';
import 'upcoming_widgets.dart';
import 'violation_service.dart';

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
      debugPrint('========================================');
      debugPrint('🔍 開始載入探索行程（司機端）');

      // ✅ 直接用 trips 表 + 計算座位
      final data = await supabase
          .from('trips')
          .select('''
          *,
          trip_members(count)
        ''')
          .eq('status', 'open')
          .order('depart_time');

      debugPrint('✅ 查詢成功，共 ${data.length} 筆行程');

      final trips = (data as List).map<Trip>((e) {
        final seatsTotal = e['seats_total'] ?? 0;
        final memberCount = (e['trip_members']?[0]?['count'] ?? 0) as int;
        final seatsLeft = seatsTotal - memberCount;

        return Trip(
          id: e['id'].toString(),
          origin: e['origin'] ?? '',
          destination: e['destination'] ?? '',
          departTime: DateTime.parse(e['depart_time']),
          seatsTotal: seatsTotal,
          seatsLeft: seatsLeft,  // ✅ 計算出來的
          status: e['status'] ?? '',
          note: e['note'] ?? '',
        );
      }).toList();

      debugPrint('✅ 解析完成，${trips.length} 筆行程');
      debugPrint('========================================');

      if (!mounted) return;
      setState(() {
        _exploreTrips = trips;
        _loadingExplore = false;
      });
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('❌ 載入行程失敗');
      debugPrint('錯誤: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('========================================');

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

    // ✅ 0️⃣ 檢查座位是否已滿
    if (trip.seatsLeft <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('行程已滿員'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // ✅ 檢查停權狀態
    final isSuspended = await ViolationService().isUserSuspended(user.id);
    if (isSuspended) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('您的帳號目前已被停權，無法加入行程。'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      debugPrint('========================================');
      debugPrint('🚗 司機發送加入申請');
      debugPrint('trip_id: ${trip.id}');
      debugPrint('user_id: ${user.id}');

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

      // 2️⃣ 檢查是否已有司機
      final existDriver = await supabase
          .from('trip_members')
          .select('id')
          .eq('trip_id', trip.id)
          .eq('role', 'driver')
          .maybeSingle();

      if (existDriver != null) {
        debugPrint('⚠️ 此行程已有司機');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('此行程已有司機'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 3️⃣ ✅ 再次確認座位
      final tripData = await supabase
          .from('trips')
          .select('creator_id, seats_total, trip_members(count)')
          .eq('id', trip.id)
          .single();

      final seatsTotal = tripData['seats_total'] as int;
      final memberCount = (tripData['trip_members']?[0]?['count'] ?? 0) as int;
      final seatsLeft = seatsTotal - memberCount;

      if (seatsLeft <= 0) {
        debugPrint('⚠️ 行程已滿員');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('行程已滿員'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 4️⃣ 查詢創建者是否開啟自動審核
      final creatorId = tripData['creator_id'] as String;

      final creatorData = await supabase
          .from('users')
          .select('auto_approve')
          .eq('id', creatorId)
          .single();

      final autoApprove = creatorData['auto_approve'] as bool? ?? false;

      debugPrint('創建者自動審核狀態: $autoApprove');

      if (autoApprove) {
        // ✅ 自動審核：直接加入
        debugPrint('✅ 自動審核開啟，直接加入行程');

        await supabase.from('trip_members').insert({
          'trip_id': trip.id,
          'user_id': user.id,
          'role': 'driver',
          'join_time': DateTime.now().toIso8601String(),
        });

        debugPrint('✅ 成功加入行程（司機）');
        debugPrint('========================================');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已成功加入行程（司機）！'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // 5️⃣ 需要審核：檢查是否已經發送過申請
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

      // 6️⃣ 發送加入申請（標記為司機）
      debugPrint('✅ 寫入 join_requests，role: driver');
      await supabase.from('join_requests').insert({
        'trip_id': trip.id,
        'user_id': user.id,
        'role': 'driver',
      });

      debugPrint('✅ 成功發送司機申請');
      debugPrint('========================================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已發送加入申請（司機），請等待創建者審核'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('========================================');
      debugPrint('❌ 發送申請失敗: $e');
      debugPrint('========================================');

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