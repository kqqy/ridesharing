import 'package:flutter/material.dart';
import 'trip_model.dart';

// ==========================================
//  1. UI 元件：乘客首頁的主體介面
// ==========================================
class PassengerHomeBody extends StatelessWidget {
  final Color themeColor;
  final VoidCallback onManageTripTap;
  final List<Trip> exploreTrips;
  final Function(Trip) onExploreDetail;
  final Function(Trip) onExploreJoin;
  final VoidCallback onCreateTrip;

  const PassengerHomeBody({
    super.key,
    required this.themeColor,
    required this.onManageTripTap,
    required this.exploreTrips,
    required this.onExploreDetail,
    required this.onExploreJoin,
    required this.onCreateTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 上方區塊 (雙搜尋框)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          color: const Color(0xFFF5F5F5), // 淺灰背景
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題列
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '探索行程',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF424242)),
                  ),
                  ElevatedButton.icon(
                    onPressed: onManageTripTap,
                    icon: const Icon(Icons.edit_calendar, size: 16, color: Colors.black54),
                    label: const Text(
                      '行程管理', 
                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // 雙搜尋框
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.my_location, size: 18, color: Colors.blue[300]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '出發地',
                              style: TextStyle(color: Colors.grey[400], fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flag, size: 18, color: Colors.red[300]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '目的地',
                              style: TextStyle(color: Colors.grey[400], fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 下方列表區塊
        Expanded(
          child: Container(
            color: const Color(0xFFF5F5F5), 
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: exploreTrips.length,
              itemBuilder: (context, index) {
                return PassengerTripCard(
                  trip: exploreTrips[index],
                  onDetailTap: () => onExploreDetail(exploreTrips[index]),
                  onJoin: () => onExploreJoin(exploreTrips[index]),
                  onChat: null,
                  onDepart: null,
                  onCancel: null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
//  2. 乘客行程卡片 (PassengerTripCard)
// ==========================================
class PassengerTripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onDetailTap;
  final VoidCallback? onJoin;   
  final VoidCallback? onChat;   
  final VoidCallback? onDepart; 
  final VoidCallback? onCancel; 
  final String? cancelText;     
  final bool hasNotification; // 控制紅點

  const PassengerTripCard({
    super.key,
    required this.trip,
    required this.onDetailTap,
    this.onJoin,
    this.onChat,
    this.onDepart,
    this.onCancel,
    this.cancelText,
    this.hasNotification = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2, 
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上半部：資訊與更多選項
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.my_location, '出發：${trip.origin}'),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.flag, '目的：${trip.destination}'),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.access_time, '時間：${trip.timeText}'),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.event_seat, '座位：${trip.seatsText}'),
                    ],
                  ),
                ),
                
                // 三個點點 + 紅點通知
                SizedBox(
                  width: 30, 
                  height: 30, 
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.more_vert, color: Colors.grey), // 固定灰色
                        onPressed: onDetailTap,
                      ),
                      if (hasNotification)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 下半部：按鈕區
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onChat != null) ...[
                  OutlinedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_bubble_outline, size: 16), 
                    label: const Text('聊天室', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                if (onDepart != null) ...[
                  OutlinedButton(
                    onPressed: onDepart,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('出發', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                ],

                if (onJoin != null)
                  ElevatedButton(
                    onPressed: onJoin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('我要共乘', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),

                if (onCancel != null)
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(cancelText ?? '取消行程', style: const TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 16), // 統一灰色
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ==========================================
//  3. 右上角選單 (PassengerTripMenu)
// ==========================================
class PassengerTripMenu extends StatelessWidget {
  final VoidCallback onUpcomingTap;
  final VoidCallback onHistoryTap;

  const PassengerTripMenu({
    super.key,
    required this.onUpcomingTap,
    required this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: CustomPaint(
            painter: TrianglePainter(),
            size: const Size(20, 10),
          ),
        ),
        Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.departure_board, color: Colors.blue),
                title: const Text('即將出發行程'),
                onTap: onUpcomingTap,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: const Text('歷史行程與統計'),
                onTap: onHistoryTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.1), 2.0, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}