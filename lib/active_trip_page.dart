import 'package:flutter/material.dart';
import 'active_trip_widgets.dart';
import 'chat_page.dart';
import 'rating_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class ActiveTripPage extends StatefulWidget {
  final String tripId; // 關鍵

  const ActiveTripPage({
    super.key,
    required this.tripId,
  });

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> {

  // ===============================
  // SOS
  // ===============================
  void _handleSOS() {
    const String sosNumber = '222';
    int sec = 2;
    Timer? timer;

    Future<void> openDialer() async {
      final uri = Uri.parse('tel:$sosNumber');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                await openDialer();
              } else {
                sec--;
                setDialogState(() {});
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Center(
                child: Text('確定要撥打求救電話?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('倒數 $sec 秒', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () async {
                        timer?.cancel();
                        Navigator.pop(dialogCtx);
                        await openDialer();
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
    ).then((_) => timer?.cancel());
  }

  // ===============================
  // 到達 → 評價
  // ===============================
  void _handleArrived() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認到達？'),
        content: const Text('確認到達後將結束行程並進行評價。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);  // 關閉確認對話框

              // ✅ 導向評價頁面，並傳入 tripId
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingPage(tripId: widget.tripId),  // ✅ 傳入 tripId
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  void _handleShare() {
    debugPrint('分享行程連結');
  }

  // ===============================
  // 聊天室（重點）
  // ===============================
  void _handleChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(tripId: widget.tripId), // ✅ 正確
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ActiveTripBody(
      origin: '逢甲夜市',        // 之後改成 DB
      destination: '台中車站',  // 之後改成 DB
      onSOS: _handleSOS,
      onArrived: _handleArrived,
      onShare: _handleShare,
      onChat: _handleChat,
    );
  }
}
