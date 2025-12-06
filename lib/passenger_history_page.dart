import 'package:flutter/material.dart';
import 'passenger_history_widgets.dart'; // 引入 UI

class PassengerHistoryPage extends StatefulWidget {
  const PassengerHistoryPage({super.key});

  @override
  State<PassengerHistoryPage> createState() => _PassengerHistoryPageState();
}

class _PassengerHistoryPageState extends State<PassengerHistoryPage> {
  // [修改] 假資料：歷史行程清單 (新增 members_list)
  final List<Map<String, dynamic>> _historyTrips = [
    {
      'date': '2025-10-20', 
      'origin': '高雄火車站', 
      'destination': '墾丁國家公園', 
      'members': 3, 
      'members_list': ['王司機 (D)', '乘客A', '乘客B'] // 包含司機和乘客名稱
    },
    {
      'date': '2025-09-05', 
      'origin': '台中機場', 
      'destination': '台北市區', 
      'members': 1, 
      'members_list': ['李司機 (D)']
    },
    {
      'date': '2025-08-12', 
      'origin': '板橋', 
      'destination': '新竹科學園區', 
      'members': 4, 
      'members_list': ['張司機 (D)', '乘客C', '乘客D', '乘客E']
    },
  ];

  // 處理「個人統計」按鈕點擊
  void _handleStatsTap() {
    // 這裡通常會導航到統計圖表頁面
    print('點擊了個人統計按鈕');
  }

  // [修改] 處理單張卡片點擊 (顯示成員列表)
  void _handleCardTap(Map<String, dynamic> trip) {
    // 準備要顯示的詳細內容列表
    List<Widget> details = [
        Text('出發地：${trip['origin']}'),
        Text('目的地：${trip['destination']}'),
        const SizedBox(height: 10),
        const Text('成員列表：', style: TextStyle(fontWeight: FontWeight.bold)),
        
        // 遍歷成員列表，逐一顯示
        ...?((trip['members_list'] as List<String>?)?.map((name) => Text(' - $name')).toList())
        
    ];


    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('行程詳情 (${trip['date']})'),
        content: Column(
            // 使用 Column 讓內容垂直排列，並使用 mainAxisSize.min 確保彈窗大小適應內容
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: details,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('關閉')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PassengerHistoryBody(
      historyTrips: _historyTrips,
      onStatsTap: _handleStatsTap,
      onCardTap: _handleCardTap,
    );
  }
}