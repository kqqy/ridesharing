import 'package:flutter/material.dart';

// 乘客首頁的主體介面 UI
class PassengerHomeBody extends StatelessWidget {
  final Color themeColor;

  const PassengerHomeBody({super.key, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0, 
        toolbarHeight: 0,
      ),
      
      // 頁面主體 (Body)
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER ROW: 探索行程標題 與 行程管理按鈕 (並排)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 左側：探索行程標題
                Text(
                  '探索行程',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                
                // 右側：行程管理按鈕
                ElevatedButton.icon(
                  onPressed: () {
                    // ⚠️ 已經移除提示，這裡只剩下空的操作
                  },
                  icon: const Icon(Icons.edit_calendar, size: 18),
                  label: const Text('行程管理'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[700],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // 2. 核心內容區 (閒置畫面)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 80,
                      color: themeColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '目前還沒有行程',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}