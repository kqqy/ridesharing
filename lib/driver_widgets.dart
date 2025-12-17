import 'package:flutter/material.dart';
import 'trip_model.dart';

// ==========================================
//  1. UI 元件：司機首頁的主體介面
// ==========================================
class DriverHomeBody extends StatelessWidget {
  final Color themeColor;
  final Trip? currentActiveTrip;
  final bool isManageMenuVisible;
  final List<Trip> exploreTrips;
  final Function(Trip) onJoinTrip;
  final Function(Trip) onExploreDetail; 

  final VoidCallback onManageTap;      
  final VoidCallback onMenuClose;      
  final Function(String) onMenuSelect; 
  
  final VoidCallback onSOS;
  final VoidCallback onArrived;
  final VoidCallback onShare;
  final VoidCallback onChat;

  const DriverHomeBody({
    super.key,
    required this.themeColor,
    required this.currentActiveTrip,
    required this.isManageMenuVisible,
    required this.exploreTrips,
    required this.onJoinTrip,
    required this.onExploreDetail,
    required this.onManageTap,
    required this.onMenuClose,
    required this.onMenuSelect,
    required this.onSOS,
    required this.onArrived,
    required this.onShare,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onMenuClose,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // 1. 底層介面
          currentActiveTrip != null 
              ? DriverActiveTripView(
                  trip: currentActiveTrip!,
                  onSOS: onSOS,
                  onArrived: onArrived,
                  onShare: onShare,
                  onChat: onChat,
                ) 
              : DriverExploreView(
                  themeColor: themeColor,
                  trips: exploreTrips,
                  onJoin: onJoinTrip,
                  onDetailTap: onExploreDetail,
                ),      

          // 2. 上方區塊 (標題 + 雙搜尋欄)
          if (currentActiveTrip == null)
            Container(
              height: 150,
              width: double.infinity,
              color: const Color(0xFFF5F5F5).withOpacity(0.95),
              padding: const EdgeInsets.fromLTRB(20, 45, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '探索行程', 
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF424242)
                    )
                  ),
                  const SizedBox(height: 15),
                  
                  // Row 包裹兩個搜尋框
                  Row(
                    children: [
                      // 左邊：出發地搜尋
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // [修改] 圖示改為灰色
                              Icon(Icons.my_location, size: 18, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '出發地',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 10), // 中間間距

                      // 右邊：目的地搜尋
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // [修改] 圖示改為灰色
                              Icon(Icons.flag, size: 18, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '目的地',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 15,
                                  ),
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

          // 3. 右上按鈕：行程管理
          if (currentActiveTrip == null)
            Positioned(
              top: 40,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: onManageTap,
                icon: const Icon(Icons.edit_calendar, size: 18),
                label: const Text('行程管理'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, 
                  foregroundColor: Colors.green[700], 
                  elevation: 2, 
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),

          // 4. 浮動視窗：行程管理選單
          if (isManageMenuVisible) 
            Positioned(
              top: 85, 
              right: 20, 
              child: DriverManageMenu(
                onUpcomingTap: () => onMenuSelect('即將出發行程'),
                onHistoryTap: () => onMenuSelect('歷史行程與統計'),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
//  2. UI 元件：探索列表視圖
// ==========================================
class DriverExploreView extends StatelessWidget {
  final Color themeColor;
  final List<Trip> trips;
  final Function(Trip) onJoin;
  final Function(Trip) onDetailTap;

  const DriverExploreView({
    super.key, 
    required this.themeColor, 
    required this.trips, 
    required this.onJoin,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.drive_eta_rounded, size: 80, color: themeColor),
            ),
            const SizedBox(height: 20),
            const Text('目前還沒有行程', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      );
    }
    return Container(
      color: const Color(0xFFF5F5F5),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 160, left: 20, right: 20, bottom: 20),
        itemCount: trips.length,
        itemBuilder: (context, index) => DriverExploreTripCard(
          trip: trips[index], 
          onJoin: () => onJoin(trips[index]),
          onDetailTap: () => onDetailTap(trips[index]),
        ),
      ),
    );
  }
}

// ==========================================
//  3. UI 元件：司機探索行程卡片
// ==========================================
class DriverExploreTripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onJoin;
  final VoidCallback onDetailTap; 

  const DriverExploreTripCard({
    super.key, 
    required this.trip, 
    required this.onJoin,
    required this.onDetailTap, 
  });

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 0,
                ),
                child: const Text('我要加入', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
//  4. UI 元件：行程進行中畫面
// ==========================================
class DriverActiveTripView extends StatelessWidget {
  final Trip trip;
  final VoidCallback onSOS;
  final VoidCallback onArrived;
  final VoidCallback onShare;
  final VoidCallback onChat;

  const DriverActiveTripView({super.key, required this.trip, required this.onSOS, required this.onArrived, required this.onShare, required this.onChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [const Icon(Icons.flag, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text('目的地：${trip.destination}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))]),
              const SizedBox(height: 16),
              Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)), child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.map, size: 50, color: Colors.grey), SizedBox(height: 10), Text('Google Map 預留區', style: TextStyle(color: Colors.grey, fontSize: 18))])))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.red), SizedBox(width: 5), Text('路徑偏移', style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold))]), ElevatedButton.icon(onPressed: onSOS, icon: const Icon(Icons.sos, color: Colors.white), label: const Text('一鍵求助'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)))]),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: OutlinedButton.icon(onPressed: onShare, icon: const Icon(Icons.share), label: const Text('分享行程'), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 15)))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: onChat, icon: const Icon(Icons.message, color: Colors.blue), label: const Text('聊天室'), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: Colors.blue)))), const SizedBox(width: 8), Expanded(child: ElevatedButton.icon(onPressed: onArrived, icon: const Icon(Icons.check_circle), label: const Text('已到達'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 15), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))))]),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
//  5. UI 元件：行程管理選單
// ==========================================
class DriverManageMenu extends StatelessWidget {
  final VoidCallback onUpcomingTap;
  final VoidCallback onHistoryTap;

  const DriverManageMenu({super.key, required this.onUpcomingTap, required this.onHistoryTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(padding: const EdgeInsets.only(right: 40.0), child: CustomPaint(painter: TrianglePainter(), size: const Size(20, 10))),
        Container(
          width: 200,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))]),
          child: Column(children: [
            ListTile(leading: const Icon(Icons.departure_board, color: Colors.blue), title: const Text('即將出發行程'), onTap: onUpcomingTap), 
            const Divider(height: 1), 
            ListTile(leading: const Icon(Icons.history, color: Colors.grey), title: const Text('歷史行程與統計'), onTap: onHistoryTap)
          ]),
        ),
      ],
    );
  }
}

// ==========================================
//  6. 其他通用元件 (SOS, Painter, etc.)
// ==========================================

class SOSCountdownDialog extends StatelessWidget {
  const SOSCountdownDialog({super.key});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), title: const Center(child: Text('確定要撥打求救電話?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))), content: const Column(mainAxisSize: MainAxisSize.min, children: [Text('倒數 2 秒', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent))]), actions: [Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: const Text('確定')), OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: const Text('取消'))])]);
  }
}

class DriverRatePassengerDialog extends StatelessWidget {
  const DriverRatePassengerDialog({super.key});
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> passengers = [{'name': '乘客 1', 'rating': 4}, {'name': '乘客 2', 'rating': 5}, {'name': '乘客 3', 'rating': 3}];
    return Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Container(padding: const EdgeInsets.all(20), constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9), child: Column(mainAxisSize: MainAxisSize.min, children: [const Center(child: Text('評價乘客', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))), const Divider(), Expanded(child: ListView.builder(itemCount: passengers.length, itemBuilder: (context, index) { final p = passengers[index]; return RatePassengerCard(name: p['name'], initialRating: p['rating'], passengerIndex: index); })), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('完成評價', style: TextStyle(fontSize: 18))))])));
  }
}

class RatePassengerCard extends StatefulWidget {
  final String name; final int initialRating; final int passengerIndex;
  const RatePassengerCard({super.key, required this.name, required this.initialRating, required this.passengerIndex});
  @override
  State<RatePassengerCard> createState() => _RatePassengerCardState();
}

class _RatePassengerCardState extends State<RatePassengerCard> {
  int _rating = 5; bool _isPolite = true; bool _isPunctual = true; final TextEditingController _commentController = TextEditingController();
  @override
  void initState() { super.initState(); _rating = widget.initialRating; }
  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged) { return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 16)), Row(children: [Checkbox(value: value, onChanged: (newValue) => onChanged(true), activeColor: Colors.green), const Text('是'), const SizedBox(width: 10), Checkbox(value: !value, onChanged: (newValue) => onChanged(false), activeColor: Colors.red), const Text('否')])]); }
  @override
  Widget build(BuildContext context) { return Card(margin: const EdgeInsets.only(bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(widget.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (index) { return Padding(padding: const EdgeInsets.symmetric(horizontal: 1.0), child: GestureDetector(onTap: () { setState(() { _rating = index + 1; }); }, child: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 24))); }))]), const Divider(height: 20), _buildToggleRow('是否準時', _isPunctual, (val) => setState(() => _isPunctual = val)), const SizedBox(height: 10), _buildToggleRow('是否禮貌', _isPolite, (val) => setState(() => _isPolite = val)), const SizedBox(height: 20), Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('評論', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(width: 15), Expanded(child: TextField(controller: _commentController, maxLines: 4, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), hintText: '輸入你的評論...', isDense: true, contentPadding: const EdgeInsets.all(10))))])]))); }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) { final paint = Paint()..color = Colors.white..style = PaintingStyle.fill; final path = Path(); path.moveTo(size.width / 2, 0); path.lineTo(0, size.height); path.lineTo(size.width, size.height); path.close(); canvas.drawShadow(path, Colors.black.withOpacity(0.1), 2.0, false); canvas.drawPath(path, paint); }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}