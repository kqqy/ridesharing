import 'package:flutter/material.dart';
import 'passenger_history_widgets.dart'; // 引入 UI
import 'passenger_stats_page.dart'; // [新增] 引入個人統計頁面

class PassengerHistoryPage extends StatefulWidget {
  const PassengerHistoryPage({super.key});

  @override
  State<PassengerHistoryPage> createState() => _PassengerHistoryPageState();
}

class _PassengerHistoryPageState extends State<PassengerHistoryPage> {
  // 假資料：歷史行程清單
  final List<Map<String, dynamic>> _historyTrips = [
    {
      'date': '2025-10-20', 
      'origin': '高雄火車站', 
      'destination': '墾丁國家公園', 
      'members': 3, 
      'members_list': ['王司機 (D)', '乘客A', '乘客B'] 
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

  // [修改] 處理「個人統計」按鈕點擊：加入導航
  void _handleStatsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PassengerStatsPage()),
    );
  }

  // 處理單張卡片點擊 (顯示成員列表)
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