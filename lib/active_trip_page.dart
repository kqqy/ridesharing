import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'active_trip_widgets.dart';
import 'chat_page.dart';
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
  final supabase = Supabase.instance.client;
  bool _isCreator = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('trip_members')
          .select('role')
          .eq('trip_id', widget.tripId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null) {
        final role = data['role'] as String;
        if (mounted) {
          setState(() {
            _isCreator = (role == 'creator' || role == 'driver');
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('檢查角色失敗: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ===============================
  // SOS（原樣）
  // ===============================
  void _handleSOS() {
    const String sosNumber = '110';
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
      builder: (dialogContext) => AlertDialog(  // ✅ 改名避免混淆
        title: const Text('確認到達？'),
        content: const Text('確認後將進入評價頁面'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),  // ✅ 使用 dialogContext
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // ✅ 關閉確認對話框

              // ✅ 檢查是否還 mounted
              if (!mounted) return;

              // 顯示 Loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );

              try {
                debugPrint('========================================');
                debugPrint('✅ 開始更新行程狀態為 completed');
                debugPrint('trip_id: ${widget.tripId}');

                // 更新行程狀態
                await supabase
                    .from('trips')
                    .update({'status': 'completed'})
                    .eq('id', widget.tripId);

                debugPrint('✅ 行程狀態更新成功');
                debugPrint('========================================');

                if (!mounted) return;
                Navigator.pop(context); // ✅ 關閉 Loading

                if (!mounted) return;

                // ✅ 進入評價頁面
                debugPrint('🎯 導航到評價頁面，tripId: ${widget.tripId}');

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RatingPage(tripId: widget.tripId),
                  ),
                );

              } catch (e, stackTrace) {
                debugPrint('========================================');
                debugPrint('❌ 更新狀態失敗: $e');
                debugPrint('Stack trace: $stackTrace');
                debugPrint('========================================');

                if (!mounted) return;
                Navigator.pop(context); // ✅ 關閉 Loading

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('操作失敗：$e')),
                );
              }
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ 不再傳固定 origin/destination
    // ✅ ActiveTripBody 會用 tripId 自己去 Supabase trips 表抓 origin/destination
    return ActiveTripBody(
      tripId: widget.tripId,
      isCreator: _isCreator,
      onSOS: _handleSOS,
      onArrived: _handleArrived,
      onShare: _handleShare,
      onChat: _handleChat,
    );
  }
}
