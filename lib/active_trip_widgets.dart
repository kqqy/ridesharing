import 'package:flutter/material.dart';

// ==========================================
//  UI 元件：行程進行中頁面主體 (通用版)
// ==========================================
class ActiveTripBody extends StatelessWidget {
  final VoidCallback onSOS;
  final VoidCallback onArrived;
  final VoidCallback onShare;
  final VoidCallback onChat;

  const ActiveTripBody({
    super.key,
    required this.onSOS,
    required this.onArrived,
    required this.onShare,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 底層：全螢幕 Google Map 預留區
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[300], // 灰色背景模擬地圖
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    'Google Map 導航畫面',
                    style: TextStyle(fontSize: 20, color: Colors.grey[500], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 2. 上方懸浮文字：路徑偏移
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '路徑偏移',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. 右上角：求救電話 (SOS)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'btn_sos',
              onPressed: onSOS,
              backgroundColor: Colors.red,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.sos, color: Colors.white, size: 28),
            ),
          ),

          // 4. 下方功能區
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 左下角：分享行程
                FloatingActionButton(
                  heroTag: 'btn_share',
                  onPressed: onShare,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.share),
                ),

                // 中間下方：已到達
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: ElevatedButton.icon(
                    onPressed: onArrived,
                    icon: const Icon(Icons.check_circle, size: 24),
                    label: const Text('已到達', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                  ),
                ),

                // 右下角：聊天室
                FloatingActionButton(
                  heroTag: 'btn_chat',
                  onPressed: onChat,
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: const Icon(Icons.chat_bubble),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}