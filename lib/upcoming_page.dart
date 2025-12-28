import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'trip_model.dart';
import 'upcoming_widgets.dart';
import 'chat_page.dart';
import 'active_trip_page.dart';
import 'violation_service.dart';

final supabase = Supabase.instance.client;

class UpcomingPage extends StatefulWidget {
  final bool isDriver;

  const UpcomingPage({super.key, required this.isDriver});

  @override
  State<UpcomingPage> createState() => _UpcomingPageState();
}

class _UpcomingPageState extends State<UpcomingPage> {
  final ViolationService _violationService = ViolationService();

  List<Trip> _upcomingTrips = [];
  Map<String, String> _roleMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTrips();
  }

  Future<void> _fetchUpcomingTrips() async {
    setState(() => _loading = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final data = await supabase
          .from('trip_members')
          .select('trip_id, role, trips!inner(*)')
          .eq('user_id', user.id);

      final trips = <Trip>[];
      final roleMap = <String, String>{};

      for (var row in data) {
        final trip = row['trips'] as Map<String, dynamic>;

        final status = (trip['status'] ?? '') as String;
        if (status != 'open' && status != 'started') continue;

        final id = trip['id'].toString();
        roleMap[id] = row['role'] as String;

        trips.add(
          Trip(
            id: id,
            origin: (trip['origin'] ?? '') as String,
            destination: (trip['destination'] ?? '') as String,
            departTime: DateTime.parse(trip['depart_time'] as String),
            seatsTotal: (trip['seats_total'] ?? 0) as int,
            seatsLeft: (trip['seats_left'] ?? 0) as int,
            status: status,
            note: (trip['note'] ?? '') as String,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _upcomingTrips = trips;
        _roleMap = roleMap;
        _loading = false;
      });
    } catch (e) {
      debugPrint('fetch upcoming trips error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('讀取即將出發行程失敗：$e')),
      );
    }
  }

  void _handleDetailTrip(Trip trip) {
    final role = _roleMap[trip.id] ?? 'passenger';
    final isCreator = role == 'creator';

    if (isCreator) {
      showDialog(
        context: context,
        builder: (context) => SimpleDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('行程選項'),
          children: [
            SimpleDialogOption(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => PassengerTripDetailsDialog(trip: trip),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('行程詳細資訊', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => JoinRequestsDialog(tripId: trip.id),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.person_add_alt_1, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('加入申請', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => PassengerTripDetailsDialog(trip: trip),
      );
    }
  }

  void _handleChatTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(tripId: trip.id)),
    );
  }

  Future<void> _handleDepartTrip(Trip trip) async {
    try {
      final me = supabase.auth.currentUser;
      if (me == null) return;

      final data = await supabase
          .from('trip_members')
          .select('''
          user_id,
          role,
          users!trip_members_user_id_fkey(
            nickname
          )
        ''')
          .eq('trip_id', trip.id);

      final List<String> members = [];

      for (final row in data) {
        final userId = row['user_id'] as String;
        final role = (row['role'] ?? '') as String;
        final nickname = (row['users']?['nickname'] ?? '未知') as String;

        final isMe = userId == me.id;

        String nameText = isMe ? '我' : nickname;

        if (role == 'creator') {
          nameText += ' (創建者)';
        } else if (role == 'driver') {
          nameText += ' (司機)';
        }

        members.add(nameText);
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PassengerManifestDialog(
          members: members,
          onConfirm: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActiveTripPage(tripId: trip.id),
              ),
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('載入 trip_members 失敗: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('載入成員失敗：$e')),
      );
    }
  }

  Future<void> _handleCancelTrip(Trip trip) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final role = _roleMap[trip.id] ?? 'passenger';
    final isCreator = role == 'creator';

    // ✅ 計算距離出發時間
    final now = DateTime.now();
    final departTime = trip.departTime;
    final hoursUntilDepart = departTime.difference(now).inHours;

    // ✅ 決定違規門檻
    final violationThreshold = isCreator ? 6 : 1;
    final willViolate = hoursUntilDepart < violationThreshold;

    // 確認對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCreator ? '確定要取消行程？' : '確定要離開行程？'),
        content: Text(willViolate
            ? (isCreator
            ? '警告：距離出發時間不足 6 小時，取消將記錄違規！'
            : '警告：距離出發時間不足 1 小時，離開將記錄違規！')
            : (isCreator
            ? '取消後，所有成員將被移除。'
            : '離開後，您將不再是此行程的成員。')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: willViolate ? Colors.red : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(isCreator ? '確定取消' : '確定離開'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // ✅ 如果會違規，先記錄
      if (willViolate) {
        await _violationService.recordViolation(
          userId: user.id,
          tripId: trip.id,
          violationType: isCreator ? 'cancel_trip' : 'leave_trip',
          reason: isCreator
              ? '在出發前 $hoursUntilDepart 小時取消行程'
              : '在出發前 $hoursUntilDepart 小時離開行程',
        );

        debugPrint('⚠️ 已記錄違規：${isCreator ? '取消行程' : '離開行程'}');
      }

      if (isCreator) {
        await supabase.from('trips').delete().eq('id', trip.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(willViolate ? '已取消行程（已記錄違規）' : '已取消行程'),
              backgroundColor: willViolate ? Colors.orange : null,
            ),
          );
        }
      } else {
        await supabase
            .from('trip_members')
            .delete()
            .eq('trip_id', trip.id)
            .eq('user_id', user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(willViolate ? '已離開行程（已記錄違規）' : '已離開行程'),
              backgroundColor: willViolate ? Colors.orange : null,
            ),
          );
        }
      }

      await _fetchUpcomingTrips();
    } catch (e) {
      debugPrint('取消/離開行程失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return  Scaffold(
        appBar: AppBar(
          title: Text('即將出發'),
          leading: BackButton(),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('即將出發'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: UpcomingBody(
        isDriver: widget.isDriver,
        upcomingTrips: _upcomingTrips,
        roleMap: _roleMap,
        onCancelTrip: _handleCancelTrip,
        onChatTrip: _handleChatTrip,
        onDetailTap: _handleDetailTrip,
        onDepartTrip: _handleDepartTrip,
      ),
    );
  }
}