import 'package:flutter/material.dart';
import 'rating_widgets.dart'; // [修正] 引入更名後的 UI

class RatingPage extends StatefulWidget { // [修改] 更名為 RatingPage
  const RatingPage({super.key});

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  // 模擬需要評價的對象資料
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

  void _handleSubmit() {
    // 這裡通常會呼叫 API 送出資料
    print('評價完成！詳細資料如下：');
    for (var target in _targets) {
      print('${target['name']} (${target['role']}): ${target['rating']} 星, 評語: ${target['controller'].text}');
    }

    // 完成後回到首頁 (清除所有堆疊回到最底層)
    Navigator.of(context).popUntil((route) => route.isFirst);
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

    return RatingBody( // [修正] 使用 RatingBody
      ratingCards: cards,
      onSubmit: _handleSubmit,
    );
  }
}