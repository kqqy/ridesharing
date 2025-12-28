import 'package:flutter/material.dart';
import 'rating_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class RatingPage extends StatefulWidget {
  final String tripId;

  const RatingPage({super.key, required this.tripId});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  List<Map<String, dynamic>> _targets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTripMembers();
  }

  Future<void> _loadTripMembers() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('trip_members')
          .select('user_id, role, users!trip_members_user_id_fkey(nickname)')
          .eq('trip_id', widget.tripId)
          .neq('user_id', user.id);

      final targets = data.map((m) {
        return {
          'user_id': m['user_id'],
          'name': m['users']['nickname'] ?? '未知',
          'role': m['role'] == 'driver' ? '司機' : '乘客',
          'rating': 5,
          'controller': TextEditingController(),
        };
      }).toList();

      setState(() {
        _targets = targets;
        _loading = false;
      });
    } catch (e) {
      debugPrint('載入成員失敗: $e');
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (var target in _targets) {
      target['controller'].dispose();
    }
    super.dispose();
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

    try {
      // 1️⃣ 提交所有評分
      for (var i = 0; i < _targets.length; i++) {
        final target = _targets[i];
        debugPrint('評價 ${i + 1}/${_targets.length}: ${target['name']} - ${target['rating']} 星');

        await supabase.from('ratings').insert({
          'trip_id': widget.tripId,
          'from_user': user.id,
          'to_user': target['user_id'],
          'rating': target['rating'],
          'comment': target['controller'].text,
          'rating_type': 'trip',
        });
      }

      debugPrint('✅ 所有評分已提交');

      // 2️⃣ 更新行程狀態為 completed
      debugPrint('🔄 開始更新行程狀態...');

      final updateResult = await supabase
          .from('trips')
          .update({'status': 'completed'})
          .eq('id', widget.tripId)
          .select();

      debugPrint('✅ 更新結果: $updateResult');

      // 驗證
      final verifyResult = await supabase
          .from('trips')
          .select('id, status')
          .eq('id', widget.tripId)
          .single();

      debugPrint('✅ 驗證結果 - id: ${verifyResult['id']}, status: ${verifyResult['status']}');
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

    // ✅ 如果沒有要評價的人，也要更新狀態
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
                    debugPrint('沒有要評價的成員，但仍需更新行程狀態');
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