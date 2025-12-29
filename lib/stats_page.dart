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
      if (userId == null) {
        debugPrint('❌ 用戶未登入');
        return;
      }

      debugPrint('========================================');
      debugPrint('📊 開始載入統計資料');
      debugPrint('user_id: $userId');

      // 1️⃣ 計算司機行程次數
      final driverData = await supabase
          .from('trip_members')
          .select('id')
          .eq('user_id', userId)
          .eq('role', 'driver');

      final driverCount = driverData.length;
      debugPrint('✅ 司機行程次數: $driverCount');

      // 2️⃣ 計算乘客行程次數（包含 creator）
      final passengerData = await supabase
          .from('trip_members')
          .select('id')
          .eq('user_id', userId)
          .or('role.eq.passenger,role.eq.creator');

      final passengerCount = passengerData.length;
      debugPrint('✅ 乘客行程次數: $passengerCount');

      // 3️⃣ 取得評價資料（手動查詢）
      final ratingsData = await supabase
          .from('ratings')
          .select('rating, comment, created_at, from_user')
          .eq('to_user', userId)
          .order('created_at', ascending: false);

      debugPrint('✅ 查詢到 ${ratingsData.length} 則評價');

      double totalScore = 0;
      int totalRatings = 0;  // ✅ 加上計數器
      List<Map<String, dynamic>> tempReviews = [];

      if (ratingsData.isNotEmpty) {
        // ✅ 先計算所有評分的平均（不論有沒有評論）
        for (var r in ratingsData) {
          totalScore += (r['rating'] as num).toDouble();
          totalRatings++;
        }

        _averageRating = totalScore / totalRatings;
        debugPrint('✅ 平均評分: ${_averageRating.toStringAsFixed(2)} (共 $totalRatings 則評價)');

        // ✅ 再收集有評論的評價（最多 10 筆）
        for (var r in ratingsData) {
          final comment = r['comment']?.toString() ?? '';
          if (tempReviews.length < 10 && comment.isNotEmpty) {
            // 手動查詢評分者的 nickname
            final fromUserId = r['from_user'] as String;
            String nickname = '匿名使用者';

            try {
              final userInfo = await supabase
                  .from('users')
                  .select('nickname')
                  .eq('id', fromUserId)
                  .maybeSingle();

              if (userInfo != null) {
                nickname = userInfo['nickname'] ?? '匿名使用者';
              }
            } catch (e) {
              debugPrint('⚠️ 查詢 nickname 失敗 (user_id: $fromUserId): $e');
            }

            tempReviews.add({
              'name': nickname,
              'rating': r['rating'] as int,
              'comment': comment,
            });

            debugPrint('  - $nickname: ${r['rating']}星 - $comment');
          }
        }

        debugPrint('✅ 收集到 ${tempReviews.length} 則有評論的評價');
      } else {
        debugPrint('⚠️ 沒有收到任何評價');
      }

      debugPrint('✅ 統計資料載入完成');
      debugPrint('========================================');

      if (mounted) {
        setState(() {
          _driverTrips = driverCount;
          _passengerTrips = passengerCount;
          _reviews = tempReviews;
          _loading = false;
        });
      }

    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('❌ 載入統計資料失敗: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('========================================');

      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('讀取統計資料失敗: $e')),
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