import 'package:flutter/material.dart';
import 'history_widgets.dart'; // 引入 HistoryBody
import 'stats_page.dart'; // 引入統計頁面

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key}); // 確保這裡是 const

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // 假資料
  final List<Map<String, dynamic>> _historyTrips = [
    {
      'date': '2025-10-20', 
      'time': '16:00',
      'origin': '高雄火車站', 
      'destination': '墾丁國家公園', 
      'members_list': ['王司機 (D)', '乘客A', '乘客B'] 
    },
    {
      'date': '2025-09-05', 
      'time': '09:30',
      'origin': '台中機場', 
      'destination': '台北市區', 
      'members_list': ['李司機 (D)', '乘客C']
    },
    {
      'date': '2025-08-12', 
      'time': '18:50',
      'origin': '板橋', 
      'destination': '新竹科學園區', 
      'members_list': ['張司機 (D)', '乘客C', '乘客D', '乘客E']
    },
  ];

  void _handleStatsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatsPage()),
    );
  }

  void _handleCardTap(Map<String, dynamic> trip) {
    List<Widget> details = [
        Text('出發地：${trip['origin']}'),
        Text('目的地：${trip['destination']}'),
        const SizedBox(height: 10),
        const Text('成員列表：', style: TextStyle(fontWeight: FontWeight.bold)),
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
    // 這裡呼叫的是 history_widgets.dart 中的 HistoryBody
    return HistoryBody(
      historyTrips: _historyTrips,
      onStatsTap: _handleStatsTap,
      onCardTap: _handleCardTap,
    );
  }
}