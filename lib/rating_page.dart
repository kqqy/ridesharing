import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rating_widgets.dart';

class RatingPage extends StatefulWidget {
  final String tripId; // ✅ 關鍵

  const RatingPage({
    super.key,
    required this.tripId,
  });

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  final supabase = Supabase.instance.client;

  // 你原本的 UI 假資料（完全不動）
  final List<Map<String, dynamic>> _targets = [
    {
      'name': '王大明',
      'role': '司機',
      'rating': 5,
      'controller': TextEditingController(),
    },
    {
      'name': '乘客 A',
      'role': '乘客',
      'rating': 5,
      'controller': TextEditingController(),
    },
  ];

  @override
  void dispose() {
    for (var t in _targets) {
      t['controller'].dispose();
    }
    super.dispose();
  }

  void _updateRating(int index, int rating) {
    setState(() {
      _targets[index]['rating'] = rating;
    });
  }

  // ===============================
  // ⭐ 行程生命週期終點
  // ===============================
  Future<void> _handleSubmit() async {
    try {
      // ✅ 結束行程
      await supabase
          .from('trips')
          .update({'status': 'completed'})
          .eq('id', widget.tripId);

      // 回到首頁
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('結束行程失敗: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('結束行程失敗')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RatingBody(
      ratingCards: List.generate(_targets.length, (i) {
        final t = _targets[i];
        return RateMemberCard(
          name: t['name'],
          role: t['role'],
          currentRating: t['rating'],
          commentController: t['controller'],
          onRatingChanged: (v) => _updateRating(i, v),
        );
      }),
      onSubmit: _handleSubmit,
    );
  }
}
