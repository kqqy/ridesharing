import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; 
import 'setting.dart';
import 'driver_home.dart';
import 'passenger_home.dart';
import 'active_trip_page.dart'; 
import 'trip_model.dart'; 
import 'rating_page.dart'; // [新增]

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  bool isDriver = false;
  bool isLoading = false;

  RealtimeChannel? _tripChannel; // [修改] 使用 RealtimeChannel

  @override
  void initState() {
    super.initState();
    _setupTripListener(); 
  }

  @override
  void dispose() {
    if (_tripChannel != null) {
      supabase.removeChannel(_tripChannel!); // [修改] 正確移除 Channel
    }
    super.dispose();
  }

  // [修改] 使用正確的 channel API 監聽
  void _setupTripListener() {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    _tripChannel = supabase.channel('public:trips');
    
    _tripChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'trips',
          callback: (payload) {
            if (!mounted) return;
            
            debugPrint('Realtime Event Received: ${payload.toString()}'); // [新增]
            debugPrint('New Record: ${payload.newRecord}'); // [新增]

            final newStatus = payload.newRecord['status'] as String?;
            final tripId = payload.newRecord['id'] as String;
            
            debugPrint('Trip ID: $tripId, New Status: $newStatus'); // [新增]

            if (newStatus == 'started') {
              debugPrint('Realtime: Trip $tripId status changed to started');
              _checkAndNavigateIfMember(tripId, currentUser.id);
            } else if (newStatus == 'completed') {
              debugPrint('Realtime: Trip $tripId status changed to completed');
              _checkAndNavigateToRatingIfMember(tripId, currentUser.id);
            }
          },
        )
        .subscribe((status, error) {
          debugPrint('Realtime Channel Status: $status'); // [新增] 監聽連線狀態
          if (error != null) {
            debugPrint('Realtime Channel Error: $error');
          }
        });
  }

  Future<void> _checkAndNavigateIfMember(String tripId, String userId) async {
    // 檢查當前使用者是否是該行程的成員
    final member = await supabase
        .from('trip_members')
        .select('user_id')
        .eq('trip_id', tripId)
        .eq('user_id', userId)
        .maybeSingle();

    if (member != null) {
      debugPrint('Realtime: Current user is a member of trip $tripId. Navigating to ActiveTripPage.');

      // 檢查是否已經在 ActiveTripPage 上，避免重複導航
      // 可以通過檢查路由棧來實現，但最簡單的方式是確保上下文是有效的
      if (mounted) {
        // 導航到 ActiveTripPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveTripPage(tripId: tripId),
          ),
        );
      }
    }
  }

  Future<void> _checkAndNavigateToRatingIfMember(String tripId, String userId) async {
    final member = await supabase
        .from('trip_members')
        .select('user_id')
        .eq('trip_id', tripId)
        .eq('user_id', userId)
        .maybeSingle();

    if (member != null) {
      debugPrint('Realtime: Current user is a member of trip $tripId. Navigating to RatingPage.');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RatingPage(tripId: tripId),
          ),
        );
      }
    }
  }

  // 處理切換身分的邏輯
  Future<void> _handleSwitchRole() async {
    if (isDriver) {
      // 情況 B: 當前是司機，準備切換為乘客 -> 直接切換
      setState(() {
        isDriver = false;
      });
    } else {
      // 情況 A: 當前是乘客，準備切換為司機 -> 檢查是否已註冊司機
      await _checkAndSwitchToDriver();
    }
  }

  Future<void> _checkAndSwitchToDriver() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      // 檢查 driver_profiles 是否有資料
      final data = await supabase
          .from('driver_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null) {
        // 已經是司機 -> 切換
        if (mounted) {
          setState(() {
            isDriver = true;
          });
        }
      } else {
        // 還不是司機 -> 跳出註冊視窗
        if (mounted) _showDriverRegistrationDialog();
      }
    } catch (e) {
      debugPrint('Check driver profile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('檢查司機身分失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 顯示 "第一次當司機" 的填寫視窗
  // [還原] 還原為原本簡單的對話框樣式 (無 Cancel 按鈕，barrierDismissible: false)
  void _showDriverRegistrationDialog() {
    final TextEditingController carTypeController = TextEditingController();
    final TextEditingController licensePlateController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // 點擊旁邊不能關閉，強迫填寫 (符合原本 UI)
      builder: (context) {
        return AlertDialog(
          title: const Text("第一次當司機?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min, // 視窗高度包覆內容即可
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("請填寫以下資料", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 15),
              TextField(
                controller: carTypeController,
                decoration: const InputDecoration(
                  labelText: "車種",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: licensePlateController,
                decoration: const InputDecoration(
                  labelText: "車牌",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            // [還原] 只有一個確定按鈕
            ElevatedButton(
              onPressed: () async {
                final carType = carTypeController.text.trim();
                final licensePlate = licensePlateController.text.trim();

                if (carType.isEmpty || licensePlate.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請填寫完整資料')));
                  return;
                }

                // 註冊邏輯
                Navigator.pop(context); // 1. 關閉視窗
                await _registerDriver(carType, licensePlate); // 2. 註冊
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // 配合預設風格
                foregroundColor: Colors.white,
              ),
              child: const Text("確定"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registerDriver(String carType, String licensePlate) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      await supabase.from('driver_profiles').insert({
        'user_id': user.id,
        'car_type': carType,
        'license_plate': licensePlate,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          isDriver = true; // 註冊成功，切換為司機
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('司機身分開通成功！')));
      }
    } catch (e) {
      debugPrint('Register driver error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('註冊失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ==========================================
  //  UI 介面部分 (UI)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final Color currentColor = isDriver ? Colors.green.shade300 : Colors.blue.shade300;
    final String currentRole = isDriver ? '司機' : '乘客';

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentRole, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: currentColor,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
            child: ElevatedButton.icon(
              // 這裡呼叫邏輯部分的函式
              onPressed: _handleSwitchRole, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: currentColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: Text(
                isDriver ? '切換乘客' : '切換司機',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // 根據角色顯示對應的檔案
      body: isDriver 
          ? DriverHome(themeColor: currentColor) 
          : PassengerHome(themeColor: currentColor),
    );
  }
}