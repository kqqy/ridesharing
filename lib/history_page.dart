import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'history_widgets.dart';
import 'stats_page.dart'; // ⭐ 你的個人統計頁
import 'trip_model.dart';

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
    _fetchHistoryTrips();
  }

  // ===============================
  // 撈歷史行程（completed / cancelled）
  // ===============================
  Future<void> _fetchHistoryTrips() async {
    try {
      final data = await supabase
          .from('trips')
          .select()
          .or('status.eq.completed,status.eq.cancelled')
          .order('depart_time', ascending: false);

      final trips = (data as List).map<Map<String, dynamic>>((e) {
        final dt = DateTime.parse(e['depart_time']);
        return {
          'id': e['id'],
          'date': '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}',
          'time': '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
          'origin': e['origin'] ?? '',
          'destination': e['destination'] ?? '',
          'members_list': ['司機', '乘客'], // 之後接 trip_members
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _historyTrips = trips;
        _loading = false;
      });
    } catch (e) {
      debugPrint('fetch history error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ===============================
  // ⭐ 個人統計（重點）
  // ===============================
  void _handleStatsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StatsPage(),
      ),
    );
  }

  // 點擊單一歷史行程（目前先留空）
  void _handleCardTap(Map<String, dynamic> trip) {
    debugPrint('點擊歷史行程: ${trip['id']}');
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
      onStatsTap: _handleStatsTap, // ✅ 關鍵
      onCardTap: _handleCardTap,
    );
  }
}
