import 'package:flutter/material.dart';
import 'setting.dart';
import 'driver_home.dart';    
import 'passenger_home.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ==========================================
  //  邏輯控制部分 (Logic)
  // ==========================================
  
  bool isDriver = false; // false=乘客, true=司機

  // 處理切換身分的邏輯
  void _handleSwitchRole() {
    if (!isDriver) {
      // 情況 A: 當前是乘客，準備切換為司機 -> 跳出註冊視窗
      _showDriverRegistrationDialog();
    } else {
      // 情況 B: 當前是司機，準備切換為乘客 -> 直接切換
      setState(() {
        isDriver = false;
      });
    }
  }

  // 顯示 "第一次當司機" 的填寫視窗
  void _showDriverRegistrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 點擊旁邊不能關閉，強迫按確定或取消(這裡只做確定)
      builder: (context) {
        return AlertDialog(
          title: const Text("第一次當司機?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min, // 視窗高度包覆內容即可
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("請填寫以下資料", style: TextStyle(color: Colors.grey)),
              SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                  labelText: "車種",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: "車牌",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // 1. 關閉視窗
                Navigator.pop(context);
                // 2. 執行切換身分為司機的動作
                setState(() {
                  isDriver = true;
                });
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

  // ==========================================
  //  UI 介面部分 (UI)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final Color currentColor = isDriver ? Colors.green.shade300 : Colors.blue.shade300;
    final String currentRole = isDriver ? '司機' : '乘客';

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