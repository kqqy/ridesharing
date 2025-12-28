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
      // ✅ 先取得所有參與的行程
      final data = await supabase
          .from('trip_members')
          .select('role, join_time, trips!inner(*)')
          .eq('user_id', user.id);

      debugPrint('📊 查詢到該用戶參與的所有行程: ${data.length}');

      // ✅ 列出每個行程的狀態
      for (var p in data) {
        final tripData = p['trips'] as Map<String, dynamic>;
        debugPrint('  - 出發地: ${tripData['origin']}, 目的地: ${tripData['destination']}, 狀態: ${tripData['status']}');
      }

      // ✅ 過濾出已完成、已取消、已結束的
      final filteredData = data.where((p) {
        final tripData = p['trips'] as Map<String, dynamic>;
        final status = tripData['status'] as String;

        final isHistory = status == 'completed' || status == 'canceled' || status == 'finished';

        if (isHistory) {
          debugPrint('  ✅ 符合歷史條件: $status (${tripData['origin']} → ${tripData['destination']})');
        }

        return isHistory;
      }).toList();

      debugPrint('📊 過濾後的歷史行程數量: ${filteredData.length}');
      debugPrint('========================================');

      final history = filteredData.map((p) {
        final tripData = p['trips'] as Map<String, dynamic>;

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

        return {
          'date': (tripData['depart_time'] as String).substring(0, 10),
          'time': (tripData['depart_time'] as String).substring(11, 16),
          'origin': tripData['origin'] ?? '',
          'destination': tripData['destination'] ?? '',
          'members_list': [
            p['role'] == 'driver' ? '我 (司機)' : '我 (乘客)'
          ],
          'status': displayStatus,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _historyTrips = history;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ 載入歷史失敗: $e');
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