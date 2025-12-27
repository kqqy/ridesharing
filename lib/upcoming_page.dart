import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'trip_model.dart';
import 'upcoming_widgets.dart';
import 'chat_page.dart';
import 'active_trip_page.dart';
import 'violation_service.dart';
import 'passenger_create_trip_page.dart'; // ✅ 你建立行程那頁（檔名請換成你的實際檔名）

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
      if (mounted) {
        setState(() {
          _upcomingTrips = [];
          _loading = false;
        });
      }
      return;
    }

    try {
      // ✅ 先抓「自己創建」的行程（creator_id = 自己）
      final rows = await supabase
          .from('trips')
          .select('id, origin, destination, depart_time, seats_total, seats_left, status, note')
          .eq('creator_id', user.id)
          .inFilter('status', ['open', 'started'])
          .order('depart_time', ascending: true);

      final trips = rows.map<Trip>((r) => Trip(
        id: r['id'] as String,
        origin: (r['origin'] ?? '') as String,
        destination: (r['destination'] ?? '') as String,
        departTime: DateTime.parse(r['depart_time'] as String),
        seatsTotal: (r['seats_total'] ?? 0) as int,
        seatsLeft: (r['seats_left'] ?? 0) as int,
        status: (r['status'] ?? 'open') as String,
        note: (r['note'] ?? '') as String,
      )).toList();

      if (!mounted) return;
      setState(() {
        _upcomingTrips = trips;
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('讀取行程失敗（DB）：${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('讀取行程失敗：$e')),
      );
    }
  }

  // ✅ 建立行程（按鈕）→ 建立成功回來後刷新
  Future<void> _goCreateTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PassengerCreateTripPage()),
    );

    // 你如果已把 PassengerCreateTripPage 改成 pop(tripId)，這裡 result 就是 tripId
    if (result != null) {
      await _fetchUpcomingTrips(); // ✅ 回來就刷新
    }
  }

  // ===============================
  // 取消/離開（你原本邏輯保留）
  // ===============================
  void _handleCancelTrip(Trip trip) {
    bool willBeViolation = false;
    if (widget.isDriver) {
      willBeViolation = _violationService.isDriverCancelViolation(trip.departTime);
    } else {
      willBeViolation = _violationService.isPassengerLeaveViolation(trip.departTime);
    }

    Widget title = widget.isDriver ? const Text('確定取消行程？') : const Text('⚠️ 退出警告');

    Widget content;
    if (widget.isDriver) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('取消後將通知所有乘客，且無法復原。'),
          if (willBeViolation) ...[
            const SizedBox(height: 10),
            const Text('注意：距離出發時間不足 6 小時', style: TextStyle(color: Colors.red)),
            const Text('此次取消將被記錄違規！', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ]
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (willBeViolation) ...[
            const Text('若在出發前 1 小時內退出，', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 5),
            const Text('將會有放鳥紀錄！', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          ] else ...[
            const Text('確定要退出此行程嗎？'),
          ]
        ],
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: title,
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('我再想想'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final userId = supabase.auth.currentUser?.id;
              if (userId == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('未登入，無法執行操作')),
                  );
                }
                return;
              }

              try {
                if (willBeViolation) {
                  final violationType = widget.isDriver ? 'driver_cancel' : 'passenger_no_show';
                  await _violationService.recordViolation(
                    userId: userId,
                    tripId: trip.id,
                    violationType: violationType,
                    reason: widget.isDriver ? '司機取消行程' : '乘客臨時退出',
                  );
                }

                // TODO: 真正取消/退出要更新 DB status 或刪 join
                // await supabase.from('trips').update({'status':'canceled'}).eq('id', trip.id);

                // ✅ 操作完刷新
                await _fetchUpcomingTrips();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(willBeViolation ? '已取消並記錄違規' : '已成功取消'),
                      backgroundColor: willBeViolation ? Colors.red : Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失敗: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _handleChatTrip(Trip trip) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(tripId: trip.id)));
  }

  void _handleDepartTrip(Trip trip) {
    final List<String> tripMembers = ['司機', '我 (乘客)', '乘客 B'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PassengerManifestDialog(
        members: tripMembers,
        onConfirm: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ActiveTripPage(tripId: trip.id)),
          );
        },
      ),
    );
  }

  void _showTripDetails(Trip trip) {
    final List<Map<String, dynamic>> fakeMembers = [
      {'name': '王小明', 'role': '司機', 'rating': 4.8},
    ];

    showDialog(
      context: context,
      builder: (context) => PassengerTripDetailsDialog(trip: trip, members: fakeMembers),
    );
  }

  void _handleTripDetail(Trip trip) {
    // ✅ 你原本用 index 判斷是不是自己創建，現在可以更準：creator_id == 自己
    // 但 Trip model 目前沒 creatorId 欄位，所以先用「全部都是自己創建」的情境：
    final bool isCreatedByMe = !widget.isDriver;

    if (isCreatedByMe) {
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
                _showTripDetails(trip);
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
                showDialog(context: context, builder: (context) => const JoinRequestsDialog());
              },
              child: const Row(
                children: [
                  Icon(Icons.person_add_alt_1, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('加入要求', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      _showTripDetails(trip);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 加一個右上角「新增行程」按鈕 + 下拉刷新
    return Scaffold(
      appBar: AppBar(
        title: const Text('即將出發行程'),
        actions: [
          if (!widget.isDriver)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _goCreateTrip,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUpcomingTrips,
              child: UpcomingBody(
                isDriver: widget.isDriver,
                upcomingTrips: _upcomingTrips,
                onCancelTrip: _handleCancelTrip,
                onChatTrip: _handleChatTrip,
                onDetailTap: _handleTripDetail,
                onDepartTrip: widget.isDriver ? null : _handleDepartTrip,
              ),
            ),
    );
  }
}
