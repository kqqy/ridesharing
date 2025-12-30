import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'passenger_widgets.dart';
import 'trip_model.dart';
import 'passenger_create_trip_page.dart';
import 'upcoming_page.dart';
import 'upcoming_widgets.dart';
import 'history_page.dart';
import 'violation_service.dart';

final supabase = Supabase.instance.client;

class PassengerHome extends StatefulWidget {
  final Color themeColor;

  const PassengerHome({super.key, required this.themeColor});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  List<Trip> _exploreTrips = [];
  bool _loadingExplore = true;
  bool _showManageMenu = false;  // ✅ 加上這個

  // ✅ 搜尋相關變數
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  String _searchOrigin = '';
  String _searchDestination = '';

  @override
  void initState() {
    super.initState();
    _loadExploreTrips();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadExploreTrips() async {
    setState(() => _loadingExplore = true);

    try {
      debugPrint('========================================');
      debugPrint('🔍 開始載入行程');
      debugPrint('搜尋條件 - 出發地: "$_searchOrigin", 目的地: "$_searchDestination"');

      // ✅ 改成動態類型
      dynamic query = supabase
          .from('trips')
          .select('''
          *,
          trip_members(*)
        ''')
          .eq('status', 'open');

      // ✅ 如果有搜尋出發地
      if (_searchOrigin.isNotEmpty) {
        query = query.ilike('origin', '%$_searchOrigin%');
        debugPrint('✅ 篩選出發地包含: $_searchOrigin');
      }

      // ✅ 如果有搜尋目的地
      if (_searchDestination.isNotEmpty) {
        query = query.ilike('destination', '%$_searchDestination%');
        debugPrint('✅ 篩選目的地包含: $_searchDestination');
      }

      // ✅ 排序
      query = query.order('depart_time');

      final data = await query;

      debugPrint('✅ 查詢成功，共 ${data.length} 筆行程');

      final trips = (data as List).map((e) {
        final seatsTotal = e['seats_total'] ?? 0;
        final memberCount = (e['trip_members'] as List<dynamic>?)?.length ?? 0;
        final seatsLeft = seatsTotal - memberCount;

        return Trip(
          id: e['id'].toString(),
          origin: (e['origin'] ?? '') as String,
          destination: (e['destination'] ?? '') as String,
          departTime: DateTime.parse(e['depart_time'] as String),
          seatsTotal: seatsTotal,
          seatsLeft: seatsLeft,
          status: (e['status'] ?? '') as String,
          note: (e['note'] ?? '') as String,
          tripMembers: (e['trip_members'] as List<dynamic>?)
                  ?.map((m) => m as Map<String, dynamic>)
                  .toList() ??
              [],
        );
      }).toList();

      debugPrint('✅ 解析完成，${trips.length} 筆行程');
      debugPrint('========================================');

      if (mounted) {
        setState(() {
          _exploreTrips = trips;
        });
      }
    } catch (e) {
      debugPrint('========================================');
      debugPrint('❌ 載入行程失敗: $e');
      debugPrint('========================================');
    } finally {
      if (mounted) {
        setState(() => _loadingExplore = false);
      }
    }
  }

  // ✅ 搜尋處理
  void _handleSearch() {
    setState(() {
      _searchOrigin = _originController.text.trim();
      _searchDestination = _destinationController.text.trim();
    });
    _loadExploreTrips();
  }

  // ✅ 清除搜尋
  void _handleClearSearch() {
    setState(() {
      _originController.clear();
      _destinationController.clear();
      _searchOrigin = '';
      _searchDestination = '';
    });
    _loadExploreTrips();
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
    showDialog(
      context: context,
      builder: (_) => PassengerTripDetailsDialog(
        trip: trip,
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

      // 2️⃣ ✅ 再次確認座位（避免競態條件）
      final tripData = await supabase
          .from('trips')
          .select('creator_id, seats_total, trip_members(*)')
          .eq('id', trip.id)
          .single();

      final seatsTotal = tripData['seats_total'] as int;
      final memberCount = (tripData['trip_members'] as List<dynamic>?)?.length ?? 0;
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

      // 3️⃣ 查詢創建者是否開啟自動審核
      final creatorId = tripData['creator_id'] as String;

      final creatorData = await supabase
          .from('users')
          .select('auto_approve')
          .eq('id', creatorId)
          .single();

      final autoApprove = creatorData['auto_approve'] as bool? ?? false;

      debugPrint('創建者自動審核狀態: $autoApprove');

      if (autoApprove) {
        // ✅ 自動審核：直接加入 trip_members
        debugPrint('✅ 自動審核開啟，直接加入行程');

        await supabase.from('trip_members').insert({
          'trip_id': trip.id,
          'user_id': user.id,
          'role': 'passenger',
          'join_time': DateTime.now().toIso8601String(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已成功加入行程！'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // 4️⃣ 需要審核：檢查是否已經發送過申請
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

      // 5️⃣ 發送加入申請
      debugPrint('✅ 寫入 join_requests...');
      await supabase.from('join_requests').insert({
        'trip_id': trip.id,
        'user_id': user.id,
        'role': 'passenger',
      });

      debugPrint('✅ 成功發送加入申請');

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
    final user = supabase.auth.currentUser;
    if (user != null) {
      final isSuspended = await ViolationService().isUserSuspended(user.id);
      if (isSuspended) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('您的帳號目前已被停權，無法建立行程。'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

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
              loadingExplore: _loadingExplore,  // ✅ 加上這個
              onExploreDetail: _handleTripDetail,
              onExploreJoin: _handleJoinTrip,
              onCreateTrip: _handleCreateTrip,
              // ✅ 搜尋相關參數
              originController: _originController,
              destinationController: _destinationController,
              onSearch: _handleSearch,
              onClearSearch: _handleClearSearch,
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
      ),
    );
  }
}