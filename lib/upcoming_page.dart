import 'package:flutter/material.dart';
import 'trip_model.dart';
import 'upcoming_widgets.dart'; // 引入 UI 元件
import 'chat_page.dart';        
import 'active_trip_page.dart'; 

class UpcomingPage extends StatefulWidget {
  final bool isDriver; 

  const UpcomingPage({super.key, required this.isDriver});

  @override
  State<UpcomingPage> createState() => _UpcomingPageState();
}

class _UpcomingPageState extends State<UpcomingPage> {
  // 假資料
  final List<Trip> _upcomingTrips = [
    Trip(id: 'upcoming_fake_1', origin: '台北車站', destination: '市政府', departTime: DateTime.parse('2025-12-06 14:30'), seatsTotal: 3, seatsLeft: 1, status: 'open', note: '無'),
    Trip(id: 'upcoming_fake_2', origin: '新竹科學園區', destination: '桃園高鐵站', departTime: DateTime.parse('2025-12-07 08:00'), seatsTotal: 4, seatsLeft: 2, status: 'open', note: '希望乘客不要吃東西'),
  ];

  // 處理取消/離開
  void _handleCancelTrip(Trip trip) {
    String title = widget.isDriver ? '確定取消行程？' : '⚠️ 退出警告';
    Widget content = widget.isDriver 
        ? const Text('取消後將通知所有乘客，且無法復原。')
        : const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('若在六小時內退出，', style: TextStyle(fontSize: 16)),
              SizedBox(height: 5),
              Text('將會有放鳥紀錄！', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: content,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('確定'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
        ],
        actionsAlignment: MainAxisAlignment.end,
      ),
    );
  }

  // 處理聊天室
  void _handleChatTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  // 處理出發 (乘客端)
  void _handleDepartTrip(Trip trip) {
    final List<String> tripMembers = ['司機', '我 (乘客)', '乘客 B'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PassengerManifestDialog(
        members: tripMembers,
        onConfirm: () {
          Navigator.pop(context); 
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ActiveTripPage()),
          );
        },
      ),
    );
  }

  // 顯示行程詳細資訊 Dialog (內部函式)
  void _showTripDetails(Trip trip) {
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

  // 處理詳細資訊點擊 (判斷是否顯示選單)
  void _handleTripDetail(Trip trip) {
    // 假設 List 中的第二筆行程 (_upcomingTrips[1]) 是使用者自己創建的
    // 這與 UpcomingBody 中的 isCreatedByMe 邏輯對應 (index > 0)
    bool isCreatedByMe = !widget.isDriver && _upcomingTrips.indexOf(trip) > 0;

    if (isCreatedByMe) {
      // 顯示 Popover 選單
      showDialog(
        context: context,
        builder: (context) => SimpleDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('行程選項'),
          children: [
            SimpleDialogOption(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              onPressed: () {
                Navigator.pop(context);
                _showTripDetails(trip); 
              },
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('行程詳細資訊', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            SimpleDialogOption(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              onPressed: () {
                Navigator.pop(context);
                // 顯示加入要求視窗
                showDialog(
                  context: context,
                  builder: (context) => const JoinRequestsDialog(),
                );
              },
              child: const Row(
                children: [
                  Icon(Icons.person_add_alt_1, color: Colors.orange),
                  SizedBox(width: 10),
                  Text('加入要求', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // 不是自己創建的，直接顯示詳細資訊
      _showTripDetails(trip);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UpcomingBody(
      isDriver: widget.isDriver, 
      upcomingTrips: _upcomingTrips,
      onCancelTrip: _handleCancelTrip,
      onChatTrip: _handleChatTrip,
      onDetailTap: _handleTripDetail,
      // 乘客端：傳入出發函式；司機端：null
      onDepartTrip: widget.isDriver ? null : _handleDepartTrip,
    );
  }
}