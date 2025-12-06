import 'package:flutter/material.dart';
import 'trip_model.dart'; // 引入資料結構

// ==========================================
//  1. UI 元件：乘客首頁的主體介面 UI
// ==========================================
class PassengerHomeBody extends StatelessWidget {
  final Color themeColor;
  final VoidCallback onManageTripTap;
  
  // 探索行程的資料與操作
  final List<Trip> exploreTrips; 
  final Function(Trip) onExploreDetail;
  final Function(Trip) onExploreJoin;
  
  // 點擊右下角 FAB 的回呼
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0, 
        toolbarHeight: 0,
      ),
      
      // 右下角懸浮按鈕
      floatingActionButton: FloatingActionButton(
        onPressed: onCreateTrip,
        backgroundColor: Colors.blue,
        elevation: 4,
        shape: const CircleBorder(), // 確保是圓形
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER: 標題與按鈕 ---
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '探索行程',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onManageTripTap,
                  icon: const Icon(Icons.edit_calendar, size: 18),
                  label: const Text('行程管理'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue[700],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // --- [修改] 搜尋區塊：移除箭頭，簡化文字 ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              children: [
                // 1. 出發地
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: '出發地', // [修改] 簡化文字
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: Icon(Icons.circle_outlined, color: Colors.grey, size: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                
                // [修改] 移除箭頭，改用間距
                const SizedBox(width: 12),

                // 2. 目的地
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: '目的地', // [修改] 簡化文字
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10), 

          // --- 核心內容區 (列表) ---
          Expanded(
            child: exploreTrips.isEmpty
                ? _buildEmptyState() 
                : _buildExploreList(), 
          ),
        ],
      ),
    );
  }

  // 小工具：顯示列表
  Widget _buildExploreList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: exploreTrips.length,
      itemBuilder: (context, index) {
        final trip = exploreTrips[index];
        return PassengerTripCard(
          trip: trip,
          onDetailTap: () => onExploreDetail(trip),
          onJoin: () => onExploreJoin(trip), 
          onChat: null,
          onCancel: null,
        );
      },
    );
  }

  // 小工具：顯示空狀態
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              size: 80,
              color: themeColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '目前還沒有行程',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ==========================================
//  2. 乘客行程管理選單
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
                color: Colors.black.withValues(alpha: 0.15),
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
                title: const Text('歷史行程'),
                onTap: onHistoryTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
//  3. 乘客行程卡片
// ==========================================
class PassengerTripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onDetailTap;
  final VoidCallback? onJoin;   
  final VoidCallback? onCancel; 
  final VoidCallback? onChat;   

  const PassengerTripCard({
    super.key,
    required this.trip,
    required this.onDetailTap,
    this.onJoin,
    this.onCancel,
    this.onChat,
  });

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isExploreMode = onJoin != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
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
                    _buildInfoRow(Icons.access_time, '時間：${trip.time}'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.event_seat, '座位：${trip.seats}'),
                  ],
                ),
              ),
              SizedBox(
                width: 30,
                height: 30,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onPressed: onDetailTap,
                  tooltip: '查看詳細',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          
          // FOOTER
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isExploreMode) ...[
                ElevatedButton(
                  onPressed: onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('我要共乘', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: onChat,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('聊天室'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('取消'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
//  4. 行程詳細資訊視窗
// ==========================================
class PassengerTripDetailsDialog extends StatelessWidget {
  final Trip trip;
  final List<Map<String, dynamic>> members; 

  const PassengerTripDetailsDialog({
    super.key,
    required this.trip,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('行程詳細資訊', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Google Map 路線預覽', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('行程資訊'),
                    const SizedBox(height: 8),
                    _buildDetailItem(Icons.my_location, '出發地', trip.origin),
                    _buildDetailItem(Icons.flag, '目的地', trip.destination),
                    _buildDetailItem(Icons.access_time, '出發時間', trip.time),
                    _buildDetailItem(Icons.event_seat, '剩餘座位', trip.seats),
                    _buildDetailItem(Icons.note, '備註', trip.note.isEmpty ? '無' : trip.note),
                    const SizedBox(height: 20),
                    _buildSectionTitle('成員列表'),
                    const SizedBox(height: 8),
                    ...members.map((member) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: member['role'] == '司機' ? Colors.blue[100] : Colors.orange[100],
                            radius: 18,
                            child: Icon(
                              member['role'] == '司機' ? Icons.drive_eta : Icons.person,
                              size: 20,
                              color: member['role'] == '司機' ? Colors.blue : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(member['role'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                member['rating'].toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text('$label：', style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class UpcomingTripsDialogContent extends StatelessWidget {
  final List<Trip> upcomingTrips;
  final Function(Trip) onCancelTrip;
  final Function(Trip) onChatTrip;
  final Function(Trip) onDetailTap;

  const UpcomingTripsDialogContent({
    super.key,
    required this.upcomingTrips,
    required this.onCancelTrip,
    required this.onChatTrip,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return upcomingTrips.isEmpty
        ? const Center(
            child: Text(
              '目前沒有即將出發的行程',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        : ListView.builder(
            itemCount: upcomingTrips.length,
            itemBuilder: (context, index) {
              final trip = upcomingTrips[index];
              return PassengerTripCard( 
                trip: trip,
                onDetailTap: () => onDetailTap(trip),
                onJoin: null, 
                onCancel: () => onCancelTrip(trip),
                onChat: () => onChatTrip(trip),
              );
            },
          );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width / 2, 0); path.lineTo(0, size.height); path.lineTo(size.width, size.height); path.close();
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.1), 2.0, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}