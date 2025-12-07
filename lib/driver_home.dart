import 'package:flutter/material.dart';
import 'trip_model.dart'; 
import 'driver_widgets.dart'; 
import 'chat_page.dart'; 
import 'upcoming_page.dart'; // [修正] 引入通用的 upcoming_page

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
    print('已加入行程: ${trip.destination} (靜默模式)');
  }

  // [修正] 導航邏輯
  void _handleMenuSelection(String value) {
    setState(() => _showManageMenu = false); 
    
    if (value == '即將出發行程') {
      Navigator.push(
        context,
        // 傳入 isDriver: true
        MaterialPageRoute(builder: (context) => const UpcomingPage(isDriver: true)),
      );
    } else if (value == '歷史行程') {
      _showHistoryTripsDialog();
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
              // 這裡可導向評價
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

  void _showHistoryTripsDialog() { 
    showDialog(
      context: context, 
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
        child: Container(
          padding: const EdgeInsets.all(20), 
          height: MediaQuery.of(context).size.height * 0.66, 
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                children: [
                  const Text('歷史行程', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), 
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context))
                ]
              ), 
              const Divider(), 
              const Expanded(child: Center(child: Text('目前沒有歷史行程', style: TextStyle(fontSize: 16, color: Colors.grey))))
            ]
          )
        )
      )
    ); 
  }
}