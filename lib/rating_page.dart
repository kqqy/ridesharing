import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rating_widgets.dart';

final supabase = Supabase.instance.client;

class RatingPage extends StatefulWidget {
  final String tripId;

  const RatingPage({
    super.key,
    required this.tripId,
  });

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  List<Map<String, dynamic>> _targets = [];
  bool _loading = true;
  String? _driverId;
  bool _isDriver = false;

  @override
  void initState() {
    super.initState();
    _loadTripMembers();
  }

  @override
  void dispose() {
    for (var target in _targets) {
      target['controller']?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTripMembers() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('❌ 沒有登入');
      return;
    }

    debugPrint('========================================');
    debugPrint('🎯 開始載入評價對象');
    debugPrint('trip_id: ${widget.tripId}');
    debugPrint('my user_id: ${user.id}');

    try {
      // 1️⃣ 先查詢所有成員（不排除任何人）
      final allMembers = await supabase
          .from('trip_members')
          .select('user_id, role')
          .eq('trip_id', widget.tripId);

      debugPrint('✅ 此行程總共有 ${allMembers.length} 位成員');
      for (var m in allMembers) {
        debugPrint('  - user_id: ${m['user_id']}, role: ${m['role']}');
      }

      // ✅ 改用 trip_members 找司機
      String? driverId;
      for (var m in allMembers) {
        if (m['role'] == 'driver') {
          driverId = m['user_id'];
          break;
        }
      }

      _driverId = driverId;
      _isDriver = (_driverId == user.id);
      debugPrint('司機ID: $_driverId, 我是司機: $_isDriver');

      // 2️⃣ 查詢要評價的對象（排除自己）
      final dataWithoutNickname = await supabase
          .from('trip_members')
          .select('user_id, role')
          .eq('trip_id', widget.tripId)
          .neq('user_id', user.id);

      debugPrint('✅ 排除自己後有 ${dataWithoutNickname.length} 位成員');

      // 3️⃣ 手動查詢每個人的 nickname
      final targets = <Map<String, dynamic>>[];

      for (var m in dataWithoutNickname) {
        final userId = m['user_id'] as String;
        final role = m['role'] as String;

        // 單獨查詢 nickname
        String nickname = '未知';
        try {
          final userInfo = await supabase
              .from('users')
              .select('nickname')
              .eq('id', userId)
              .maybeSingle();

          if (userInfo != null) {
            nickname = userInfo['nickname'] ?? '未知';
          }
        } catch (e) {
          debugPrint('⚠️ 查詢 nickname 失敗 (user_id: $userId): $e');
        }

        String displayRole;
        if (role == 'creator') {
          displayRole = '創建者';
        } else if (role == 'driver') {
          displayRole = '司機';
        } else {
          displayRole = '乘客';
        }

        targets.add({
          'user_id': userId,
          'name': nickname,
          'role': displayRole,
          'rating': 5,
          'controller': TextEditingController(),
        });

        debugPrint('✅ 加入評價對象: $nickname ($displayRole)');
      }

      if (mounted) {
        setState(() {
          _targets = targets;
          _loading = false;
        });
      }

      debugPrint('✅ 最終載入 ${targets.length} 位成員');
      debugPrint('========================================');
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('❌ 載入成員失敗: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('========================================');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _updateRating(int index, int newRating) {
    setState(() {
      _targets[index]['rating'] = newRating;
    });
  }

  void _handleSubmit() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    debugPrint('========================================');
    debugPrint('🎯 開始提交評價');
    debugPrint('trip_id: ${widget.tripId}');
    debugPrint('要評價的人數: ${_targets.length}');
    debugPrint('我是司機: $_isDriver');

    try {
      // 1️⃣ 提交所有評分
      for (var i = 0; i < _targets.length; i++) {
        final target = _targets[i];
        debugPrint('評價 ${i + 1}/${_targets.length}: ${target['name']} - ${target['rating']} 星');

        // ✅ 判斷評價類型
        String ratingType;
        if (_isDriver) {
          // 我是司機 → 評價乘客
          ratingType = 'driver_to_passenger';
        } else if (target['role'] == '司機') {
          // 我評價司機
          ratingType = 'passenger_to_driver';
        } else {
          // 乘客評價乘客
          ratingType = 'passenger_to_passenger';
        }

        debugPrint('  → 評價類型: $ratingType (對方角色: ${target['role']})');

        await supabase.from('ratings').insert({
          'trip_id': widget.tripId,
          'from_user': user.id,
          'to_user': target['user_id'],
          'rating': target['rating'],
          'comment': target['controller'].text.trim(),
          'rating_type': ratingType,
        });
      }

      debugPrint('✅ 所有評分已提交');

      // 2️⃣ 更新行程狀態
      debugPrint('🔄 開始更新行程狀態...');

      await supabase
          .from('trips')
          .update({'status': 'completed'})
          .eq('id', widget.tripId);

      debugPrint('✅ 行程狀態已更新為 completed');

      // 驗證
      final verifyResult = await supabase
          .from('trips')
          .select('id, status')
          .eq('id', widget.tripId)
          .single();

      debugPrint('✅ 驗證結果 - status: ${verifyResult['status']}');
      debugPrint('========================================');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('評價完成')),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('❌❌❌ 評價失敗');
      debugPrint('錯誤: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('========================================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('評價失敗: $e'),
            duration: const Duration(seconds: 5),
          ),
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

    // 如果沒有要評價的人
    if (_targets.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('行程評價'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('沒有需要評價的成員'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    debugPrint('========================================');
                    debugPrint('沒有要評價的成員，更新行程狀態');
                    debugPrint('trip_id: ${widget.tripId}');

                    await supabase
                        .from('trips')
                        .update({'status': 'completed'})
                        .eq('id', widget.tripId);

                    debugPrint('✅ 行程狀態已更新為 completed');

                    final result = await supabase
                        .from('trips')
                        .select('status')
                        .eq('id', widget.tripId)
                        .single();

                    debugPrint('驗證結果 - status: ${result['status']}');
                    debugPrint('========================================');
                  } catch (e) {
                    debugPrint('❌ 更新狀態失敗: $e');
                  }

                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                child: const Text('返回首頁'),
              ),
            ],
          ),
        ),
      );
    }

    final List<Widget> cards = List.generate(_targets.length, (index) {
      final target = _targets[index];
      return RateMemberCard(
        name: target['name'],
        role: target['role'],
        currentRating: target['rating'],
        commentController: target['controller'],
        onRatingChanged: (val) => _updateRating(index, val),
      );
    });

    return RatingBody(
      ratingCards: cards,
      onSubmit: _handleSubmit,
    );
  }
}