import 'package:flutter/material.dart';
import 'trip_model.dart';
import 'passenger_widgets.dart'; 

// ==========================================
//  1. UI 元件：即將出發行程的整頁介面 (通用版)
// ==========================================
class UpcomingBody extends StatelessWidget {
  final bool isDriver; 
  final List<Trip> upcomingTrips;
  final Function(Trip) onCancelTrip; 
  final Function(Trip) onChatTrip;
  final Function(Trip) onDetailTap;
  final Function(Trip)? onDepartTrip; // 接收 Nullable 函式

  const UpcomingBody({
    super.key,
    required this.isDriver,
    required this.upcomingTrips,
    required this.onCancelTrip,
    required this.onChatTrip,
    required this.onDetailTap,
    this.onDepartTrip,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('即將出發行程', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: upcomingTrips.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: upcomingTrips.length,
              itemBuilder: (context, index) {
                final trip = upcomingTrips[index];
                final bool isFirstCard = index == 0;

                // 決定取消按鈕的文字
                String cancelBtnText = isDriver 
                    ? '取消行程' 
                    : (isFirstCard ? '離開' : '取消行程');

                // [修正] UI 不再負責判斷身分來決定是否顯示出發按鈕
                // 而是單純判斷：如果是第一張卡片，且上層有傳入 onDepartTrip 函式，就顯示
                VoidCallback? departAction;
                if (isFirstCard && onDepartTrip != null) {
                  departAction = () => onDepartTrip!(trip);
                } else {
                  departAction = null;
                }

                Widget card = PassengerTripCard(
                  trip: trip,
                  onDetailTap: () => onDetailTap(trip),
                  onJoin: null,
                  onChat: () => onChatTrip(trip),
                  cancelText: cancelBtnText,
                  onDepart: departAction, // 傳遞處理好的 action
                  onCancel: () => onCancelTrip(trip),
                );

                if (!isDriver && !isFirstCard) {
                  return Stack(
                    children: [
                      card,
                      const Positioned(
                        left: 28,
                        bottom: 40,
                        child: Text(
                          '此行程由您創建',
                          style: TextStyle(
                            color: Colors.grey, 
                            fontSize: 12,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return card;
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.departure_board, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            '目前沒有即將出發的行程',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ==========================================
//  2. UI 元件：行程詳細資訊視窗
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

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey));
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(width: 70, child: Text('$label：', style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// ==========================================
//  3. 司機專用點名視窗 (DriverManifestDialog)
// ==========================================
class DriverManifestDialog extends StatefulWidget {
  final List<String> passengers;
  final VoidCallback onConfirm;

  const DriverManifestDialog({super.key, required this.passengers, required this.onConfirm});

  @override
  State<DriverManifestDialog> createState() => _DriverManifestDialogState();
}

class _DriverManifestDialogState extends State<DriverManifestDialog> {
  late Map<String, int> _status;

  @override
  void initState() {
    super.initState();
    _status = {for (var p in widget.passengers) p: 0};
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('目前乘客', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView(
                shrinkWrap: true,
                children: widget.passengers.map((p) => Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(p, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Row(children: [_buildStatusBtn('已上車', p, 1, Colors.green), const SizedBox(width: 10), _buildStatusBtn('未出現', p, 2, Colors.red)])]))).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), ElevatedButton(onPressed: widget.onConfirm, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white), child: const Text('確認出發'))]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBtn(String label, String p, int val, Color color) {
    final isSelected = _status[p] == val;
    return InkWell(
      onTap: () => setState(() => _status[p] = val),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: isSelected ? color : Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold))),
    );
  }
}