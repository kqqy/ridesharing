import 'package:flutter/material.dart';
import 'passenger_widgets.dart'; // 引入乘客的 UI 組件

// 乘客 Home Page (僅作為頁面容器)
class PassengerHome extends StatelessWidget {
  final Color themeColor;

  // 接收從 home_page.dart 傳來的顏色參數
  const PassengerHome({super.key, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    // 邏輯：直接回傳 UI 主體，不持有任何狀態
    return PassengerHomeBody(themeColor: themeColor);
  }
}