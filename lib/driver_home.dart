import 'package:flutter/material.dart';
import 'trip_model.dart'; 
import 'driver_widgets.dart'; // 引入 UI 元件
import 'chat_page.dart'; 
import 'upcoming_page.dart'; 
import 'history_page.dart'; // 引入 HistoryPage

class DriverHome extends StatefulWidget {
  final Color themeColor;

  const DriverHome({super.key, required this.themeColor});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  bool _showManageMenu = false; 
  Trip? _currentActiveTrip; 
  
  final List<Trip> _exploreTrips = [
    Trip(origin: '台中市政府', destination: '勤美誠品', time: '12-08 14:00', seats: '2/4', note: '徵求共乘'),
    Trip(origin: '逢甲夜市', destination: '高鐵台中站', time: '12-08 18:30', seats: '3/4', note: '行李箱可放'),
    Trip(origin: '新光三越', destination: '台中火車站', time: '12-09 10:00', seats: '1/4', note: '準時出發'),
  ];

  void _closeAllDialogs() {
    if (_showManageMenu) {
      setState(() => _showManageMenu = false);
    }
  }

  void _handleJoinTrip(Trip trip) {
    debugPrint('已加入行程: ${trip.destination} (靜默模式)');
  }

  void _handleMenuSelection(String value) {
    setState(() => _showManageMenu = false); 
    
    if (value == '即將出發行程') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UpcomingPage(isDriver: true)),
      );
    } else if (value == '歷史行程與統計') {
      Navigator.push(
        context,
        // [修正] 移除 const，改為 HistoryPage()
        MaterialPageRoute(builder: (context) => const HistoryPage()),
      );
    }
  }

  void _handleSOS() {
    showDialog(context: context, builder: (context) => const SOSCountdownDialog());
  }

  void _handleArrived() {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('確認到達？'), 
        content: const Text('這將結束目前的行程。'), 
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), 
          TextButton(
            onPressed: () { 
              Navigator.pop(context); 
              setState(() { _currentActiveTrip = null; }); 
              showDialog(context: context, builder: (context) => const DriverRatePassengerDialog());
            }, 
            child: const Text('確定到達')
          )
        ]
      )
    );
  }

  void _handleChat() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatPage()));
  }

  @override
  Widget build(BuildContext context) {
    return DriverHomeBody(
      themeColor: widget.themeColor,
      currentActiveTrip: _currentActiveTrip,
      isManageMenuVisible: _showManageMenu,
      exploreTrips: _exploreTrips, 
      onJoinTrip: _handleJoinTrip, 
      onManageTap: () => setState(() { _showManageMenu = !_showManageMenu; }),
      onMenuClose: _closeAllDialogs,
      onMenuSelect: _handleMenuSelection,
      onSOS: _handleSOS,
      onArrived: _handleArrived,
      onShare: () {}, 
      onChat: _handleChat,
    );
  }
}