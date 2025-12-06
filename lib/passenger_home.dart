import 'package:flutter/material.dart';
import 'passenger_widgets.dart'; // 引入乘客的 UI 組件
import 'trip_model.dart'; // 引入資料結構
import 'chat_page.dart'; // 引入聊天室頁面
import 'passenger_create_trip_page.dart'; // [新增] 引入創建行程頁面

class PassengerHome extends StatefulWidget {
  final Color themeColor;

  const PassengerHome({super.key, required this.themeColor});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  bool _showManageMenu = false;

  // 1. 即將出發行程
  final List<Trip> _upcomingTrips = [
    Trip(origin: '台北車站', destination: '市政府', time: '2025-12-06 14:30', seats: '1/3', note: '無'),
    Trip(origin: '新竹科學園區', destination: '桃園高鐵站', time: '2025-12-07 08:00', seats: '2/4', note: '希望乘客不要吃東西'),
  ];

  // 2. 探索行程 (首頁顯示的假資料)
  final List<Trip> _exploreTrips = [
    Trip(
      origin: '台中逢甲大學', 
      destination: '台中高鐵站', 
      time: '2025-12-06 18:00', 
      seats: '3/4', 
      note: '順路載人，歡迎共乘'
    ),
     Trip(
      origin: '台南火車站', 
      destination: '高雄巨蛋', 
      time: '2025-12-08 10:00', 
      seats: '2/4', 
      note: '目前車上有一隻寵物狗'
    ),
  ];

  void _closeMenu() {
    setState(() {
      _showManageMenu = false;
    });
  }

  void _handleManageTrip() {
    setState(() {
      _showManageMenu = !_showManageMenu; 
    });
  }

  void _handleMenuSelection(String type) {
    _closeMenu(); 
    if (type == '即將出發行程') {
      _showUpcomingTripsDialog(); 
    }
  }
  
  // 共用邏輯：取消行程
  void _handleCancelTrip(Trip trip) {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: const Text('確認操作'), 
        content: Text('您選擇了行程：${trip.destination}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉')),
        ],
      ),
    );
  }
  
  // 共用邏輯：聊天室
  void _handleChatTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  // 共用邏輯：查看詳細
  void _handleTripDetail(Trip trip) {
    final List<Map<String, dynamic>> fakeMembers = [
      {'name': '王大明', 'role': '司機', 'rating': 4.9},
      {'name': '乘客 A', 'role': '乘客', 'rating': 5.0},
    ];

    showDialog(
      context: context,
      builder: (context) => PassengerTripDetailsDialog(
        trip: trip,
        members: fakeMembers,
      ),
    );
  }

  // 處理「我要共乘」按鈕 (靜默模式)
  void _handleJoinTrip(Trip trip) {
    print('使用者已點擊加入前往 ${trip.destination} 的行程 (靜默模式)'); 
  }

  // [新增] 處理「創建行程」按鈕
  void _handleCreateTrip() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PassengerCreateTripPage()),
    );

    // 如果創建成功 (result == true)，可以在這裡刷新列表
    if (result == true) {
      print('行程創建成功，可以刷新列表');
      // setState(() { ... 重新撈取資料 ... });
    }
  }

  // 顯示「即將出發行程」視窗
  void _showUpcomingTripsDialog() {
    double dialogHeight = MediaQuery.of(context).size.height * 0.66; 

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: dialogHeight,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('即將出發行程', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                
                Expanded(
                  child: UpcomingTripsDialogContent( 
                    upcomingTrips: _upcomingTrips,
                    onCancelTrip: _handleCancelTrip,
                    onChatTrip: _handleChatTrip,
                    onDetailTap: _handleTripDetail,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double appBarHeight = AppBar().preferredSize.height;

    return Stack(
      children: [
        GestureDetector(
          onTap: _closeMenu,
          behavior: HitTestBehavior.translucent,
          child: PassengerHomeBody(
            themeColor: widget.themeColor,
            onManageTripTap: _handleManageTrip,
            exploreTrips: _exploreTrips, 
            onExploreDetail: _handleTripDetail,
            onExploreJoin: _handleJoinTrip, 
            onCreateTrip: _handleCreateTrip, // [新增] 傳入導航邏輯
          ),
        ),

        if (_showManageMenu)
          Positioned(
            top: appBarHeight + 10, 
            right: 15,
            child: PassengerTripMenu(
              onUpcomingTap: () => _handleMenuSelection('即將出發行程'),
              onHistoryTap: () => _handleMenuSelection('歷史行程'),
            ),
          ),
      ],
    );
  }
}