import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'trip_model.dart';
import 'upcoming_widgets.dart';
import 'chat_page.dart';
import 'active_trip_page.dart';

final supabase = Supabase.instance.client;

class UpcomingPage extends StatefulWidget {
  final bool isDriver;

  const UpcomingPage({super.key, required this.isDriver});

  @override
  State<UpcomingPage> createState() => _UpcomingPageState();
}

class _UpcomingPageState extends State<UpcomingPage> {
  List<Trip> _upcomingTrips = [];
  Map<String, String> _roleMap = {};  // ✅ 新增：記錄每個行程的 role
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTrips();
  }

  // ===============================
  // 讀取即將出發行程
  // ===============================
  Future<void> _fetchUpcomingTrips() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // ✅ 從 trip_members 查該用戶參與的行程
      final data = await supabase
          .from('trip_members')
          .select('trip_id, role, trips!inner(*)')
          .eq('user_id', user.id);

      // ✅ 在客戶端過濾 open 和 started（排除 completed）
      final filteredData = data.where((p) {
        final tripData = p['trips'] as Map<String, dynamic>;
        final status = tripData['status'] as String;
        return status == 'open' || status == 'started';
      }).toList();

      final trips = <Trip>[];
      final roleMap = <String, String>{};

      for (var p in filteredData) {
        final tripData = p['trips'] as Map<String, dynamic>;
        final tripId = tripData['id'].toString();

        // ✅ 記錄該行程的 role
        roleMap[tripId] = p['role'] as String;

        trips.add(Trip(
          id: tripId,
          origin: tripData['origin'] ?? '',
          destination: tripData['destination'] ?? '',
          departTime: DateTime.parse(tripData['depart_time']),
          seatsTotal: tripData['seats_total'] ?? 0,
          seatsLeft: tripData['seats_left'] ?? 0,
          status: tripData['status'] ?? '',
          note: tripData['note'] ?? '',
        ));
      }

      if (!mounted) return;
      setState(() {
        _upcomingTrips = trips;
        _roleMap = roleMap;  // ✅ 保存 role 資訊
        _loading = false;
      });
    } catch (e) {
      debugPrint('fetch upcoming trips error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ===============================
  // ❗取消 / 離開行程
  // ===============================
  void _handleCancelTrip(Trip trip) {
    // ✅ 從 roleMap 取得該行程的 role
    final role = _roleMap[trip.id] ?? 'passenger';
    final isCreator = (role == 'creator');

    String title = isCreator ? '確定取消行程？' : '⚠️ 退出警告';
    Widget content = isCreator
        ? const Text('取消後將通知所有乘客，且無法復原。')
        : const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('若在六小時內退出，', style: TextStyle(fontSize: 16)),
        SizedBox(height: 5),
        Text(
          '將會有放鳥紀錄！',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: content,
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final user = supabase.auth.currentUser;
              if (user == null) return;

              try {
                // ✅ 用 role 判斷是否為創建者
                if (isCreator) {
                  // 創建者：刪除整個行程
                  await supabase.from('trips').delete().eq('id', trip.id);
                } else {
                  // 參與者：只刪自己的記錄
                  final now = DateTime.now();
                  final hoursDiff = trip.departTime.difference(now).inHours;
                  final isFlake = hoursDiff < 6;

                  if (isFlake) {
                    await supabase.from('violations').insert({
                      'user_id': user.id,
                      'trip_id': trip.id,
                      'violation_type': 'flake',
                    });
                  }

                  await supabase
                      .from('trip_members')
                      .delete()
                      .eq('trip_id', trip.id)
                      .eq('user_id', user.id);
                }

                // 前端同步移除
                if (mounted) {
                  setState(() {
                    _upcomingTrips.removeWhere((t) => t.id == trip.id);
                    _roleMap.remove(trip.id);  // ✅ 也移除 roleMap
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('行程已移除')),
                  );
                }
              } catch (e) {
                debugPrint('cancel trip error: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('操作失敗：$e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('確定'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // ===============================
  // 聊天
  // ===============================
  void _handleChatTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(tripId: trip.id)),
    );
  }

  // ===============================
  // 乘客出發
  // ===============================
  void _handleDepartTrip(Trip trip) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PassengerManifestDialog(
        members: const ['司機', '我'],
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
  }

  // ===============================
  // UI
  // ===============================
  @override
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return UpcomingBody(
      isDriver: widget.isDriver,
      upcomingTrips: _upcomingTrips,
      roleMap: _roleMap,  // ✅ 傳入 roleMap
      onCancelTrip: _handleCancelTrip,
      onChatTrip: _handleChatTrip,
      onDetailTap: (_) {},
      onDepartTrip: widget.isDriver ? null : _handleDepartTrip,
    );
  }
}