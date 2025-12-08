import 'package:flutter/material.dart';
import 'trip_model.dart';
import 'passenger_widgets.dart'; // 借用 PassengerTripCard
import 'stats_page.dart'; // 引入統計頁面 (為了成員詳細資料跳轉)

// ==========================================
//  1. UI 元件：即將出發行程的整頁介面 (UpcomingBody)
// ==========================================
class UpcomingBody extends StatelessWidget {
  final bool isDriver; 
  final List<Trip> upcomingTrips;
  final Function(Trip) onCancelTrip; 
  final Function(Trip) onChatTrip;
  final Function(Trip) onDetailTap;
  final Function(Trip)? onDepartTrip; 

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
                
                // 邏輯：第一張卡片是參加別人的(不能出發)，後面的是自己創的(可出發)
                final bool isFirstCard = index == 0;

                String cancelBtnText;
                VoidCallback? departAction;

                if (isDriver) {
                  // --- 司機模式 ---
                  cancelBtnText = '取消行程';
                  departAction = null; 
                } else {
                  // --- 乘客模式 ---
                  if (isFirstCard) {
                    cancelBtnText = '離開';
                    departAction = null; 
                  } else {
                    cancelBtnText = '取消行程';
                    departAction = () => onDepartTrip?.call(trip);
                  }
                }

                // 判斷是否為自己創建的行程 (乘客端且不是第一張)
                bool isCreatedByMe = !isDriver && !isFirstCard;

                Widget card = PassengerTripCard(
                  trip: trip,
                  onDetailTap: () => onDetailTap(trip),
                  onJoin: null,
                  onChat: () => onChatTrip(trip),
                  cancelText: cancelBtnText,
                  onDepart: departAction, 
                  onCancel: () => onCancelTrip(trip),
                  
                  // 如果是自己創建的卡片，直接顯示紅點
                  hasNotification: isCreatedByMe,
                );

                if (isCreatedByMe) {
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
//  3. 加入要求視窗 (JoinRequestsDialog)
// ==========================================
class JoinRequestsDialog extends StatefulWidget {
  const JoinRequestsDialog({super.key});

  @override
  State<JoinRequestsDialog> createState() => _JoinRequestsDialogState();
}

class _JoinRequestsDialogState extends State<JoinRequestsDialog> {
  final List<Map<String, dynamic>> _requests = [
    {
      'id': 1, 
      'name': '新成員 A', 
      'rating': 4.5,
      'violation': 0, 
      'noShow': 2,    
    },
    {
      'id': 2, 
      'name': '新成員 B', 
      'rating': 3.8,
      'violation': 1,
      'noShow': 0,
    },
  ];

  void _removeRequest(int id) {
    setState(() {
      _requests.removeWhere((element) => element['id'] == id);
    });
  }

  void _showMemberProfile(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => MemberProfileDialog(
        name: member['name'],
        rating: member['rating'],
        violationCount: member['violation'],
        noShowCount: member['noShow'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('加入要求', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _requests.isEmpty 
              ? const Center(child: Text('目前沒有加入要求', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    return InkWell(
                      onTap: () => _showMemberProfile(req),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.orange[100],
                              child: const Icon(Icons.person, color: Colors.orange),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(req['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(req['rating'].toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // 打勾按鈕 (靜默)
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                              onPressed: () {},
                            ),
                            // 打叉按鈕 (靜默)
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
//  4. 成員資訊卡片 (MemberProfileDialog)
// ==========================================
class MemberProfileDialog extends StatelessWidget {
  final String name;
  final double rating;
  final int violationCount;
  final int noShowCount;

  const MemberProfileDialog({
    super.key,
    required this.name,
    required this.rating,
    required this.violationCount,
    required this.noShowCount,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFEBEFF5), 
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                const Divider(color: Colors.black12, thickness: 1),
                const SizedBox(height: 15),

                _buildInfoRow('違規次數', '$violationCount 次'),
                const SizedBox(height: 10),
                const Divider(color: Colors.black12, thickness: 1),
                const SizedBox(height: 15),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '平均評價',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(width: 15),
                    Row(
                      children: List.generate(5, (index) {
                        if (index < rating.floor()) {
                          return const Icon(Icons.star, color: Colors.amber, size: 24);
                        } else if (index < rating) {
                          return const Icon(Icons.star_half, color: Colors.amber, size: 24);
                        }
                        return const Icon(Icons.star_border, color: Colors.amber, size: 24);
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rating.toString(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                const Divider(color: Colors.black12, thickness: 1),
                
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('關閉', style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                ),
              ],
            ),
          ),

          Positioned(
            top: 10,
            right: 10,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const StatsPage())
                );
              },
              child: const Text(
                '詳細資料', 
                style: TextStyle(
                  color: Colors.blue, 
                  fontSize: 14, 
                  fontWeight: FontWeight.bold
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ==========================================
//  5. 乘客專用點名視窗 (PassengerManifestDialog)
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
  late Map<String, int> _status;

  @override
  void initState() {
    super.initState();
    _status = {for (var m in widget.members) m: 0};
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
            const Text('目前成員', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView(
                shrinkWrap: true,
                children: widget.members.map((name) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          _buildStatusBtn('已到達', name, 1, Colors.green),
                          const SizedBox(width: 10),
                          _buildStatusBtn('未到達', name, 2, Colors.red),
                        ],
                      )
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('取消', style: TextStyle(color: Colors.grey, fontSize: 16))
                ),
                ElevatedButton(
                  onPressed: widget.onConfirm,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text('確定', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBtn(String label, String name, int val, Color color) {
    final isSelected = _status[name] == val;
    return InkWell(
      onTap: () => setState(() => _status[name] = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ==========================================
//  6. 司機專用點名視窗 (DriverManifestDialog)
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