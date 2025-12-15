import 'package:flutter/material.dart';
import 'active_trip_widgets.dart'; // 引入 UI
import 'chat_page.dart'; // 引入聊天室
import 'rating_page.dart'; // [修正] 引入更名後的評價頁面
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';


class ActiveTripPage extends StatefulWidget {
  const ActiveTripPage({super.key});

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> {

  // 處理 SOS 求救
void _handleSOS() {
  const String sosNumber = '222'; // ✅ 改成 119 / 112 / 你的客服
  int sec = 2;
  Timer? timer;

  Future<void> openDialer() async {
    final uri = Uri(scheme: 'tel', path: sosNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri); // ✅ 跳到系統撥號畫面
    } else {
      debugPrint('無法開啟撥號畫面：$uri');
    }
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          timer ??= Timer.periodic(const Duration(seconds: 1), (t) async {
            if (sec <= 1) {
              t.cancel();
              if (Navigator.canPop(dialogCtx)) Navigator.pop(dialogCtx);
              await openDialer(); // ✅ 倒數完自動跳撥號
            } else {
              sec--;
              setDialogState(() {});
            }
          });

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Center(
              child: Text(
                '確定要撥打求救電話?',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '倒數 $sec 秒',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('倒數結束後會自動開啟撥號畫面'),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      timer?.cancel();
                      Navigator.pop(dialogCtx);
                    },
                    child: const Text('取消'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      timer?.cancel();
                      Navigator.pop(dialogCtx);
                      await openDialer(); // ✅ 立刻跳撥號
                    },
                    child: const Text('立刻開啟撥號'),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  ).then((_) {
    timer?.cancel(); // ✅ 任何方式關掉 dialog 都保證停掉 timer
  });
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