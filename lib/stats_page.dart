import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'stats_widgets.dart'; // 引入通用 UI

final supabase = Supabase.instance.client;

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _passengerTrips = 0;
  int _driverTrips = 0;
  double _averageRating = 0.0;
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 1. 計算司機行程次數 (狀態為 completed)
      final driverCount = await supabase
          .from('trips')
          .count()
          .eq('driver_id', userId)
          .eq('status', 'completed');

      // 2. 計算乘客行程次數 (從 trip_members 算)
      // 這裡簡單計算參與過的行程總數
      final passengerCount = await supabase
          .from('trip_members')
          .count()
          .eq('user_id', userId);

      // 3. 取得評價資料 (計算平均分 + 顯示評論)
      // 假設 ratings 表有關聯 profiles (透過 from_user)
      final ratingsData = await supabase
          .from('ratings')
          .select('rating, comment, created_at, profiles:from_user(name)')
          .eq('to_user', userId)
          .order('created_at', ascending: false);

      double totalScore = 0;
      List<Map<String, dynamic>> tempReviews = [];

      if (ratingsData.isNotEmpty) {
        for (var r in ratingsData) {
          totalScore += (r['rating'] as num).toDouble();
          
          // 只取有留言的顯示在列表，或全部顯示 (這裡取前 10 筆有留言的)
          if (tempReviews.length < 10 && r['comment'] != null && r['comment'].toString().isNotEmpty) {
            tempReviews.add({
              'name': r['profiles']?['name'] ?? '匿名使用者',
              'rating': r['rating'],
              'comment': r['comment'],
            });
          }
        }
        _averageRating = totalScore / ratingsData.length;
      }

      if (mounted) {
        setState(() {
          _driverTrips = driverCount;
          _passengerTrips = passengerCount;
          _reviews = tempReviews;
          _loading = false;
        });
      }

    } catch (e) {
      debugPrint('Error fetching stats: $e');
      if (mounted) {
        setState(() => _loading = false);
        // 發生錯誤時保持 0 或顯示錯誤訊息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('讀取統計資料失敗')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StatsBody(
      passengerTrips: _passengerTrips,
      driverTrips: _driverTrips,
      averageRating: _averageRating,
      reviews: _reviews,
    );
  }
}