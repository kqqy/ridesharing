import 'package:flutter/material.dart';
import 'trip_model.dart';
import 'passenger_widgets.dart'; // 引入 PassengerTripCard

// ==========================================
//  1. UI 元件：即將出發行程的整頁介面
// ==========================================
class PassengerUpcomingBody extends StatelessWidget {
  final List<Trip> upcomingTrips;
  final Function(Trip) onCancelTrip;
  final Function(Trip) onChatTrip;
  final Function(Trip) onDetailTap;
  final Function(Trip) onDepartTrip;

  const PassengerUpcomingBody({
    super.key,
    required this.upcomingTrips,
    required this.onCancelTrip,
    required this.onChatTrip,
    required this.onDetailTap,
    required this.onDepartTrip,
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

                Widget card = PassengerTripCard(
                  trip: trip,
                  onDetailTap: () => onDetailTap(trip),
                  onJoin: null,
                  onChat: () => onChatTrip(trip),
                  
                  cancelText: isFirstCard ? '離開' : '取消行程',
                  onDepart: isFirstCard ? null : () => onDepartTrip(trip),
                  onCancel: () => onCancelTrip(trip),
                );

                if (!isFirstCard) {
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

// ==========================================
//  3. 成員點名視窗 (PassengerManifestDialog)
// ==========================================
class PassengerManifestDialog extends StatefulWidget {
  final List<String> members;
  final VoidCallback onConfirm;

  const PassengerManifestDialog({
    super.key, 
    required this.members,
    required this.onConfirm,
  });

  @override
  State<PassengerManifestDialog> createState() => _PassengerManifestDialogState();
}

class _PassengerManifestDialogState extends State<PassengerManifestDialog> {
  late Map<String, int> _memberStatus;

  @override
  void initState() {
    super.initState();
    _memberStatus = {for (var m in widget.members) m: 0};
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Center(child: Text('目前成員', style: TextStyle(fontWeight: FontWeight.bold))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.members.map((name) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      _buildStatusButton(
                        label: '已到達',
                        isSelected: _memberStatus[name] == 1,
                        activeColor: Colors.green,
                        onTap: () => setState(() => _memberStatus[name] = 1),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusButton(
                        label: '未到達',
                        isSelected: _memberStatus[name] == 2,
                        activeColor: Colors.red,
                        onTap: () => setState(() => _memberStatus[name] = 2),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: widget.onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('確定出發', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusButton({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}