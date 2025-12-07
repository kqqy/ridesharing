import 'package:flutter/material.dart';
import 'active_trip_widgets.dart'; // 引入 UI
import 'chat_page.dart'; // 引入聊天室
import 'rating_page.dart'; // [修正] 引入更名後的評價頁面

class ActiveTripPage extends StatefulWidget {
  const ActiveTripPage({super.key});

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> {

  // 處理 SOS 求救
  void _handleSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Center(
          child: Text(
            '確定要撥打求救電話?',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '倒數兩秒', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('取消'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('確定'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // [修改] 處理已到達：導向評價頁面
  void _handleArrived() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認到達？'),
        content: const Text('確認到達後將結束行程並進行評價。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // 1. 關閉 Dialog
              
              // 2. 跳轉到評價頁面 (使用 pushReplacement 避免使用者按返回鍵回到行程中)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const RatingPage()), // [修正] 跳轉至 RatingPage
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  // 處理分享行程 (靜默)
  void _handleShare() {
    print('分享行程連結... (靜默模式)');
  }

  // 處理聊天室
  void _handleChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ActiveTripBody(
      onSOS: _handleSOS,
      onArrived: _handleArrived,
      onShare: _handleShare,
      onChat: _handleChat,
    );
  }
}