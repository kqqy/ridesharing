import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // [新增]
import 'setting.dart';
import 'driver_home.dart';    
import 'passenger_home.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client; // [新增] Supabase client

  // ==========================================
  //  邏輯控制部分 (Logic)
  // ==========================================
  
  bool isDriver = false; // false=乘客, true=司機
  bool isLoading = false; // [新增] Loading 狀態

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