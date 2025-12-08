import 'package:flutter/material.dart';
import 'stats_widgets.dart'; // 引入通用 UI

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  // 假資料
  final int _passengerTrips = 18;
  final int _driverTrips = 5;
  final double _averageRating = 4.3;

  // [新增] 假的評論資料
  final List<Map<String, dynamic>> _fakeReviews = [
    {
      'name': '陳小美',
      'rating': 5,
      'comment': '開車很穩，車內也很乾淨，非常愉快的共乘體驗！'
    },
    {
      'name': '王大明',
      'rating': 4,
      'comment': '準時到達，但冷氣稍微有點強，其他都很棒。'
    },
    {
      'name': 'Jason',
      'rating': 5,
      'comment': '人很好聊，還順路載我到巷口，大推！'
    },
    {
      'name': '林小姐',
      'rating': 3,
      'comment': '有點小遲到，希望下次注意時間。'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return StatsBody(
      passengerTrips: _passengerTrips,
      driverTrips: _driverTrips,
      averageRating: _averageRating,
      reviews: _fakeReviews, // [新增] 傳入評論
    );
  }
}