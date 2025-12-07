import 'package:flutter/material.dart';
import 'active_trip_widgets.dart'; // 引入 UI
import 'chat_page.dart'; // 引入聊天室

class ActiveTripPage extends StatefulWidget {
  const ActiveTripPage({super.key});

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> {

  // [修改] 處理 SOS 求救：更新視窗內容
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
            // 靜態顯示倒數文字
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
              // 取消按鈕
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('取消'),
              ),
              // 確定按鈕
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

  // 處理已到達
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
              Navigator.pop(context); // 關閉 Dialog
              Navigator.pop(context); // 回到首頁
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  // [修改] 處理分享行程：移除 SnackBar 提示 (靜默)
  void _handleShare() {
    // 這裡執行實際的分享邏輯，但介面上不顯示提示
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