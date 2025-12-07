import 'package:flutter/material.dart';
import 'stats_widgets.dart'; // [修正] 引入通用 UI

class StatsPage extends StatefulWidget { // [修改] 更名
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  // 假資料
  final int _passengerTrips = 18;
  final int _driverTrips = 5;
  final double _averageRating = 4.3;

  @override
  Widget build(BuildContext context) {
    return StatsBody( // [修正] 使用通用 Body
      passengerTrips: _passengerTrips,
      driverTrips: _driverTrips,
      averageRating: _averageRating,
    );
  }
}