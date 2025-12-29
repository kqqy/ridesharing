import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';  // ✅ 加這行
import 'history_widgets.dart';
import 'stats_page.dart';

final supabase = Supabase.instance.client;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

  List<Map<String, dynamic>> _historyTrips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('❌ 用戶未登入');
      return;
    }

    debugPrint('========================================');
    debugPrint('📊 歷史頁面：開始載入');
    debugPrint('✅ 當前用戶 ID: ${user.id}');
    setState(() => _loading = true);

    try {
      // 1️⃣ 先取得所有參與的行程
      final data = await supabase
          .from('trip_members')
          .select('role, join_time, trips!inner(*)')
          .eq('user_id', user.id);

      debugPrint('📊 查詢到該用戶參與的所有行程: ${data.length}');

      // 2️⃣ 過濾出已完成、已取消、已結束的
      final filteredData = data.where((p) {
        final tripData = p['trips'] as Map<String, dynamic>;
        final status = tripData['status'] as String;
        return status == 'completed' || status == 'canceled' || status == 'finished';
      }).toList();

      debugPrint('📊 過濾後的歷史行程數量: ${filteredData.length}');

      // 3️⃣ 為每個行程載入所有成員
      final history = <Map<String, dynamic>>[];

      for (var p in filteredData) {
        final tripData = p['trips'] as Map<String, dynamic>;
        final tripId = tripData['id'] as String;

        // ✅ 載入這個行程的所有成員
        final allMembers = await supabase
            .from('trip_members')
            .select('''
            user_id,
            role,
            users!trip_members_user_id_fkey(
              nickname
            )
          ''')
            .eq('trip_id', tripId);

        // ✅ 組合成員列表
        final membersList = <String>[];
        for (var member in allMembers) {
          final memberId = member['user_id'] as String;
          final memberRole = member['role'] as String;
          final nickname = member['users']['nickname'] ?? '未知';

          String displayRole;
          if (memberRole == 'creator') {
            displayRole = '創建者';
          } else if (memberRole == 'driver') {
            displayRole = '司機';
          } else {
            displayRole = '乘客';
          }

          // ✅ 標記是否為當前使用者
          final isMe = memberId == user.id;
          final displayName = isMe ? '$nickname (我)' : nickname;

          membersList.add('$displayName ($displayRole)');
        }

        // ✅ 決定狀態顯示文字
        String displayStatus;
        if (tripData['status'] == 'completed') {
          displayStatus = '已完成';
        } else if (tripData['status'] == 'canceled') {
          displayStatus = '已取消';
        } else if (tripData['status'] == 'finished') {
          displayStatus = '已結束';
        } else {
          displayStatus = tripData['status'];
        }

        history.add({
          'trip_id': tripId,  // ✅ 加上 trip_id
          'date': (tripData['depart_time'] as String).substring(0, 10),
          'time': (tripData['depart_time'] as String).substring(11, 16),
          'origin': tripData['origin'] ?? '',
          'destination': tripData['destination'] ?? '',
          'members_list': membersList,  // ✅ 所有成員
          'status': displayStatus,
        });
      }

      debugPrint('✅ 載入完成，共 ${history.length} 筆歷史行程');
      debugPrint('========================================');

      if (mounted) {
        setState(() {
          _historyTrips = history;
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('❌ 載入歷史失敗: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('========================================');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _handleStatsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatsPage()),
    );
  }

  void _handleCardTap(Map<String, dynamic> trip) {
    List<Widget> details = [
      Text('出發地：${trip['origin']}'),
      Text('目的地：${trip['destination']}'),
      const SizedBox(height: 10),
      const Text('成員列表：', style: TextStyle(fontWeight: FontWeight.bold)),
      ...?((trip['members_list'] as List<String>?)?.map((name) => Text(' - $name')).toList())
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('行程詳情 (${trip['date']})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 加入 loading 判斷
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return HistoryBody(
      historyTrips: _historyTrips,
      onStatsTap: _handleStatsTap,
      onCardTap: _handleCardTap,
    );
  }
}