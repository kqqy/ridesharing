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
  Map<String, String> _roleMap = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTrips();
  }

  Future<void> _fetchUpcomingTrips() async {
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
        _roleMap = roleMap;
        _loading = false;
      });
    } catch (e) {
      debugPrint('fetch upcoming trips error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _handleCancelTrip(Trip trip) {
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
                if (isCreator) {
                  await supabase.from('trips').delete().eq('id', trip.id);
                } else {
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

                if (mounted) {
                  setState(() {
                    _upcomingTrips.removeWhere((t) => t.id == trip.id);
                    _roleMap.remove(trip.id);
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

  void _handleChatTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(tripId: trip.id)),
    );
  }

  // ===============================
  // ✅ 修改：乘客出發（載入真實成員）
  // ===============================
  Future<void> _handleDepartTrip(Trip trip) async {
    try {
      // ✅ 從資料庫讀取該行程的所有成員
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

      // ✅ 組成成員名單
      final List<String> members = [];

      for (var member in data) {
        final nickname = member['users']['nickname'] ?? '未知';
        final role = member['role'] as String;

        final currentUser = supabase.auth.currentUser;
        final isMe = member['user_id'] == currentUser?.id;

        if (isMe) {
          // 如果是自己，標記為「我」
          if (role == 'creator') {
            members.add('我 (創建者)');
          } else if (role == 'driver') {
            members.add('我 (司機)');
          } else {
            members.add('我');
          }
        } else {
          // 其他人顯示暱稱 + 角色
          if (role == 'creator') {
            members.add('$nickname (創建者)');
          } else if (role == 'driver') {
            members.add('$nickname (司機)');
          } else {
            members.add(nickname);
          }
        }
      }

      if (!mounted) return;

      // ✅ 顯示點名對話框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PassengerManifestDialog(
          members: members,  // ✅ 傳入真實成員名單
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
      debugPrint('載入成員失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入成員失敗: $e')),
        );
      }
    }
  }

  void _showTripDetails(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => PassengerTripDetailsDialog(
        trip: trip,
      ),
    );
  }

  void _handleTripDetail(Trip trip) {
    final role = _roleMap[trip.id] ?? 'passenger';
    final isCreator = (role == 'creator');

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
                showDialog(
                  context: context,
                  builder: (context) => JoinRequestsDialog(tripId: trip.id),
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
      _showTripDetails(trip);
    }
  }

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
      roleMap: _roleMap,
      onCancelTrip: _handleCancelTrip,
      onChatTrip: _handleChatTrip,
      onDetailTap: _handleTripDetail,
      onDepartTrip: widget.isDriver ? null : _handleDepartTrip,
    );
  }
}