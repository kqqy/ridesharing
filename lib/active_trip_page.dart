import 'package:flutter/material.dart';
import 'active_trip_widgets.dart';
import 'rating_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class ActiveTripPage extends StatefulWidget {
  final String tripId; // ✅ 一定要有

  const ActiveTripPage({
    super.key,
    required this.tripId,
  });

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage> {
  // ===============================
  // SOS（原樣）
  // ===============================
  void _handleSOS() {
    const String sosNumber = '222';
    int sec = 2;
    Timer? timer;

    Future<void> openDialer() async {
      final uri = Uri.parse('tel:$sosNumber');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // ✅ 模擬器常沒有撥號器
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('此裝置無法開啟撥號功能（建議用實機測試）')),
        );
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
              title: const Text('確定要撥打求救電話？'),
              content: Text('倒數 $sec 秒'),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    timer?.cancel();
                    Navigator.pop(dialogCtx);
                    await openDialer();
                  },
                  child: const Text('立刻撥打'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => timer?.cancel());
  }

  // ===============================
  // 結束行程 → 評價頁
  // ===============================
  void _handleArrived() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認到達？'),
        content: const Text('確認後將進入評價頁面'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => RatingPage(tripId: widget.tripId),
                ),
              );
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  void _handleShare() {}

  @override
  Widget build(BuildContext context) {
    // ✅ 不再傳固定 origin/destination
    // ✅ ActiveTripBody 會用 tripId 自己去 Supabase trips 表抓 origin/destination
    return ActiveTripBody(
      tripId: widget.tripId,
      onSOS: _handleSOS,
      onArrived: _handleArrived,
      onShare: _handleShare,
      onChat: () {},
    );
  }
}
