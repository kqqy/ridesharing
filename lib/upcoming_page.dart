import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'trip_model.dart';
import 'upcoming_widgets.dart'; // 引入 UI 元件
import 'chat_page.dart';        
import 'active_trip_page.dart';
import 'violation_service.dart';

final supabase = Supabase.instance.client;

class UpcomingPage extends StatefulWidget {
  final bool isDriver; 

  const UpcomingPage({super.key, required this.isDriver});

  @override
  State<UpcomingPage> createState() => _UpcomingPageState();
}

class _UpcomingPageState extends State<UpcomingPage> {
  final ViolationService _violationService = ViolationService();

  // 假資料
  final List<Trip> _upcomingTrips = [
    Trip(id: 'upcoming_fake_1', origin: '台北車站', destination: '市政府', departTime: DateTime.parse('2025-12-06 14:30'), seatsTotal: 3, seatsLeft: 1, status: 'open', note: '無'),
    Trip(id: 'upcoming_fake_2', origin: '新竹科學園區', destination: '桃園高鐵站', departTime: DateTime.parse('2025-12-07 08:00'), seatsTotal: 4, seatsLeft: 2, status: 'open', note: '希望乘客不要吃東西'),
  ];

  // 處理取消/離開
  void _handleCancelTrip(Trip trip) {
    // 預先檢查違規 (僅顯示警告文字用，實際寫入在確認後)
    bool willBeViolation = false;
    if (widget.isDriver) {
      willBeViolation = _violationService.isDriverCancelViolation(trip.departTime);
    } else {
      willBeViolation = _violationService.isPassengerLeaveViolation(trip.departTime);
    }

    Widget title = widget.isDriver ? const Text('確定取消行程？') : const Text('⚠️ 退出警告');
    
    // 根據是否違規動態調整警告內容
    Widget content;
    if (widget.isDriver) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('取消後將通知所有乘客，且無法復原。'),
          if (willBeViolation) ...[
            const SizedBox(height: 10),
            const Text('注意：距離出發時間不足 6 小時', style: TextStyle(color: Colors.red)),
            const Text('此次取消將被記錄違規！', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ]
        ],
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (willBeViolation) ...[
             const Text('若在出發前 1 小時內退出，', style: TextStyle(fontSize: 16)),
             const SizedBox(height: 5),
             const Text('將會有放鳥紀錄！', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          ] else ...[
             const Text('確定要退出此行程嗎？'),
          ]
        ],
      );
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: title,
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('我再想想'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // 先關閉對話框
              
              final userId = supabase.auth.currentUser?.id;
              if (userId == null) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未登入，無法執行操作')));
                return;
              }

              try {
                // 如果構成違規，寫入紀錄
                if (willBeViolation) {
                  final violationType = widget.isDriver ? 'driver_cancel' : 'passenger_no_show'; // 或 passenger_cancel，視需求定義
                  await _violationService.recordViolation(
                    userId: userId,
                    tripId: trip.id,
                    violationType: violationType,
                    reason: widget.isDriver ? '司機取消行程' : '乘客臨時退出',
                  );
                }

                // TODO: 這裡呼叫後端 API 執行實際的「取消行程」或「退出行程」邏輯
                // await supabase.rpc('cancel_trip', ...); 

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(willBeViolation ? '已取消並記錄違規' : '已成功取消'),
                      backgroundColor: willBeViolation ? Colors.red : Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失敗: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('確定'),
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
      MaterialPageRoute(builder: (_) =>ChatPage(tripId: trip.id)),
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
            MaterialPageRoute(builder: (context) => ActiveTripPage(tripId: trip.id)),
          );
        },
      ),
    );
  }

  // 顯示行程詳細資訊 Dialog (內部函式)
  void _showTripDetails(Trip trip) {
    final List<Map<String, dynamic>> fakeMembers = [
      {'name': '王小明', 'role': '司機', 'rating': 4.8},
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
