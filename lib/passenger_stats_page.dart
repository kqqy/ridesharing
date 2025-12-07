import 'package:flutter/material.dart';
import 'passenger_stats_widgets.dart'; // 引入 UI

class PassengerStatsPage extends StatefulWidget {
  const PassengerStatsPage({super.key});

  @override
  State<PassengerStatsPage> createState() => _PassengerStatsPageState();
}

class _PassengerStatsPageState extends State<PassengerStatsPage> {
  // 假資料
  final int _passengerTrips = 18;
  final int _driverTrips = 5;
  final double _averageRating = 4.3;

  @override
  Widget build(BuildContext context) {
    return PassengerStatsBody(
      passengerTrips: _passengerTrips,
      driverTrips: _driverTrips,
      averageRating: _averageRating,
    );
  }
}