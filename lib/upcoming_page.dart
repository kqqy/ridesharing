import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'trip_model.dart';
import 'upcoming_widgets.dart'; // 引入 UI
import 'violation_service.dart'; // 引入違規服務
import 'chat_page.dart';

// ==========================================
//  即將出發行程頁面 (邏輯層)
// ==========================================

class UpcomingPage extends StatefulWidget {
  final bool isDriver; 
  const UpcomingPage({super.key, required this.isDriver});

  @override
  State<UpcomingPage> createState() => _UpcomingPageState();
}

class _UpcomingPageState extends State<UpcomingPage> {
  final supabase = Supabase.instance.client;
  final _violationService = ViolationService();
  
  List<Trip> upcomingTrips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (widget.isDriver) {
        // 司機：載入自己創建的未完成行程
        final data = await supabase
            .from('trips')
            .select()
            .eq('creator_id', user.id)
            .inFilter('status', ['open', 'started']) // open or started
            .order('depart_time');
        
        setState(() {
          upcomingTrips = (data as List).map((e) => Trip.fromMap(e)).toList();
          isLoading = false;
        });
      } else {
        // 乘客：載入自己參與的行程 (這裡簡化為查詢 trip_members 再查 trips)
        // 暫時僅模擬：查詢所有行程 (為了演示)
        // 實際應為: 
        // final memberData = await supabase.from('trip_members').select('trip_id').eq('user_id', user.id);
        // final tripIds = memberData.map((e) => e['trip_id']).toList();
        // final tripsData = await supabase.from('trips').select().inFilter('id', tripIds)...
        
        // 這裡暫時用 "所有 open 行程" 代替，方便您測試
         final data = await supabase
            .from('trips')
            .select()
            .eq('status', 'open')
            .neq('creator_id', user.id) // 排除自己建的
            .order('depart_time');

        setState(() {
          upcomingTrips = (data as List).map((e) => Trip.fromMap(e)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load upcoming trips error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 處理取消行程 (司機) 或 退出行程 (乘客)
  Future<void> _handleCancelOrLeave(Trip trip) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 1. 判斷是否會違規
    bool isViolation = false;
    String warningMessage = "確定要取消此行程嗎？";

    if (widget.isDriver) {
      if (_violationService.isDriverCancelViolation(trip.departTime)) {
        isViolation = true;
        warningMessage = "警告：距離出發時間少於 6 小時，取消行程將會被記點！\n確定要取消嗎？";
      }
    } else {
      if (_violationService.isPassengerLeaveViolation(trip.departTime)) {
        isViolation = true;
        warningMessage = "警告：距離出發時間少於 1 小時，退出行程將會被記點！\n確定要退出嗎？";
      } else {
        warningMessage = "確定要退出此行程嗎？"; // 乘客一般退出
      }
    }

    // 2. 跳出確認對話框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isViolation ? '違規警告' : '確認取消'),
        content: Text(
          warningMessage,
          style: isViolation ? const TextStyle(color: Colors.red, fontWeight: FontWeight.bold) : null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('我再想想'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isViolation ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('確定執行'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 3. 執行取消/退出邏輯
    try {
      if (widget.isDriver) {
        // 司機：取消整趟行程
        await supabase.from('trips').update({'status': 'canceled'}).eq('id', trip.id);
        
        if (isViolation) {
          await _violationService.recordViolation(
            userId: user.id,
            tripId: trip.id,
            violationType: 'late_cancel', // 遲取消
            reason: '司機於出發前 6 小時內取消',
          );
        }
      } else {
        // 乘客：退出行程 (刪除 trip_members 紀錄)
        // 暫時無法刪除，因為還沒實作加入邏輯，這裡僅記錄違規供測試
        // await supabase.from('trip_members').delete().match({...});
        
        if (isViolation) {
          await _violationService.recordViolation(
            userId: user.id,
            tripId: trip.id,
            violationType: 'late_cancel', // 這裡也算遲取消/退出
            reason: '乘客於出發前 1 小時內退出',
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isViolation ? '已取消並記錄違規' : '已成功取消/退出')),
        );
        _loadTrips(); // 重新整理列表
      }

    } catch (e) {
      debugPrint('Cancel trip error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失敗: $e')));
      }
    }
  }

  void _handleChat(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  void _handleDetail(Trip trip) {
    // 假資料演示詳細頁
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

  void _handleDepart(Trip trip) {
    // 這裡實作司機出發邏輯，或乘客點擊的行為
    debugPrint('Depart trip: ${trip.id}');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return UpcomingBody(
      isDriver: widget.isDriver,
      upcomingTrips: upcomingTrips,
      onCancelTrip: _handleCancelOrLeave,
      onChatTrip: _handleChat,
      onDetailTap: _handleDetail,
      onDepartTrip: _handleDepart,
    );
  }
}
