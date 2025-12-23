import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'history_widgets.dart'; // 你的 HistoryBody / HistoricalTripCard 在這裡

final supabase = Supabase.instance.client;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _historyTrips = [];

  @override
  void initState() {
    super.initState();
    _fetchHistoryTrips();
  }

  // ===============================
  // ✅ 撈歷史行程：completed / cancelled
  // ===============================
  Future<void> _fetchHistoryTrips() async {
    setState(() => _loading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _historyTrips = [];
          _loading = false;
        });
        return;
      }

      // 1) 先抓 trips（只抓完成/取消）
      final tripsData = await supabase
          .from('trips')
          .select('id, origin, destination, depart_time, status')
          .or('status.eq.completed,status.eq.cancelled')
          .order('depart_time', ascending: false);

      final trips = List<Map<String, dynamic>>.from(tripsData);

      // 2) 可選：抓成員（如果你還沒做 trip_members，這段會自動 fallback）
      //    假設你的表叫 trip_members，欄位：trip_id, name
      //    若你欄位不同，把 select(...) 換成你的欄位
      Map<String, List<String>> membersByTripId = {};

      try {
        final tripIds = trips.map((t) => t['id'].toString()).toList();
        if (tripIds.isNotEmpty) {
          // 用 in 篩 trip_id（你剛說 in 那個改 or —— 這裡用 in 才對，因為是 trip_id 多值）
          final membersData = await supabase
              .from('trip_members')
              .select('trip_id, name')
              .inFilter('trip_id', tripIds);

          for (final row in List<Map<String, dynamic>>.from(membersData)) {
            final tid = row['trip_id']?.toString();
            final name = row['name']?.toString();
            if (tid == null || name == null || name.isEmpty) continue;
            membersByTripId.putIfAbsent(tid, () => []);
            membersByTripId[tid]!.add(name);
          }
        }
      } catch (_) {
        // 你還沒建 trip_members 表/欄位也沒關係，會用 fallback
      }

      // 3) 組成 HistoryBody 需要的格式
      final mapped = trips.map<Map<String, dynamic>>((t) {
        final dt = DateTime.tryParse(t['depart_time']?.toString() ?? '');
        final date = (dt == null)
            ? ''
            : '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        final time = (dt == null)
            ? ''
            : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

        final tripId = t['id'].toString();
        final members = membersByTripId[tripId] ?? ['無成員資料'];

        return {
          'id': tripId,
          'date': date,
          'time': time,
          'origin': t['origin']?.toString() ?? '',
          'destination': t['destination']?.toString() ?? '',
          'members_list': members,
          'status': t['status']?.toString() ?? '',
        };
      }).toList();

      setState(() {
        _historyTrips = mapped;
        _loading = false;
      });
    } catch (e) {
      debugPrint('fetch history trips error: $e');
      setState(() => _loading = false);
    }
  }

  void _handleStatsTap() {
    // 你原本的統計頁/邏輯放這裡（不動 UI）
    debugPrint('stats tap');
  }

  void _handleCardTap(Map<String, dynamic> trip) {
    // 你原本點卡片要做什麼放這裡（不動 UI）
    debugPrint('tap trip id=${trip['id']}');
  }

  @override
  Widget build(BuildContext context) {
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
