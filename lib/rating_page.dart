import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rating_widgets.dart';

final supabase = Supabase.instance.client;

class RatingPage extends StatefulWidget {
  final String tripId; // ⭐ 關鍵：一定要有

  const RatingPage({
    super.key,
    required this.tripId,
  });

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  // 模擬需要評價的對象資料（UI 不動）
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

  // ===============================
  // ⭐ 完成評價（重點）
  // ===============================
  Future<void> _handleSubmit() async {
    try {
      // 1️⃣ 這裡未來可以存評價（現在先不動）
      for (var target in _targets) {
        debugPrint(
          '${target['name']} (${target['role']}): '
              '${target['rating']} 星, 評語: ${target['controller'].text}',
        );
      }

      // 2️⃣ ⭐ 核心：把行程改成 completed
      await supabase
          .from('trips')
          .update({
        'status': 'completed',
      })
          .eq('id', widget.tripId);

      // 3️⃣ 回到首頁（觸發首頁重新 initState 撈資料）
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      debugPrint('rating submit error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('評價送出失敗，請稍後再試')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
      onSubmit: _handleSubmit, // ⭐ 接上
    );
  }
}
