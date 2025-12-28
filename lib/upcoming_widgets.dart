import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';  // ✅ 加這行
import 'trip_model.dart';
import 'passenger_widgets.dart';
import 'stats_page.dart';

final supabase = Supabase.instance.client;  // ✅ 加這行

// ==========================================
//  1. UI 元件：即將出發行程的整頁介面 (UpcomingBody)
// ==========================================
class UpcomingBody extends StatelessWidget {
  final bool isDriver;
  final List<Trip> upcomingTrips;
  final Map<String, String> roleMap;  // ✅ 新增：每個 trip 的 role
  final Function(Trip) onCancelTrip;
  final Function(Trip) onChatTrip;
  final Function(Trip) onDetailTap;
  final Function(Trip)? onDepartTrip;

  const UpcomingBody({
    super.key,
    required this.isDriver,
    required this.upcomingTrips,
    required this.roleMap,  // ✅ 新增
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

          // ✅ 從 roleMap 取得該行程的 role
          final role = roleMap[trip.id] ?? 'passenger';
          final isCreator = (role == 'creator');

          String cancelBtnText;
          VoidCallback? departAction;

          if (isCreator) {
            // ✅ 創建者：可以取消行程、可以出發
            cancelBtnText = '取消行程';
            departAction = () => onDepartTrip?.call(trip);
          } else {
            // ✅ 普通乘客：可以離開、不能出發
            cancelBtnText = '離開';
            departAction = null;
          }

          Widget card = PassengerTripCard(
            trip: trip,
            onDetailTap: () => onDetailTap(trip),
            onJoin: null,
            onChat: () => onChatTrip(trip),
            cancelText: cancelBtnText,
            onDepart: departAction,
            onCancel: () => onCancelTrip(trip),
            hasNotification: isCreator,  // ✅ 創建者顯示紅點
          );

          if (isCreator) {
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
// ==========================================
//  2. UI 元件：行程詳細資訊視窗
// ==========================================
class PassengerTripDetailsDialog extends StatefulWidget {
  final Trip trip;

  const PassengerTripDetailsDialog({
    super.key,
    required this.trip,
  });

  @override
  State<PassengerTripDetailsDialog> createState() => _PassengerTripDetailsDialogState();
}

class _PassengerTripDetailsDialogState extends State<PassengerTripDetailsDialog> {
  List<Map<String, dynamic>> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  // ✅ 從資料庫載入成員資料
  Future<void> _loadMembers() async {
    setState(() => _loading = true);

    try {
      // ✅ 從資料庫讀取該行程的所有成員
      final data = await supabase
          .from('trip_members')
          .select('''
            user_id,
            role,
            users!trip_members_user_id_fkey(
              nickname
            )
          ''')
          .eq('trip_id', widget.trip.id);

      // ✅ 對每個成員，查詢評分
      final members = <Map<String, dynamic>>[];

      for (var member in data) {
        final userId = member['user_id'] as String;

        // 查詢平均評分
        final ratingData = await supabase
            .from('ratings')
            .select('rating')
            .eq('to_user', userId);

        double avgRating = 5.0;
        if (ratingData.isNotEmpty) {
          final sum = ratingData.fold<int>(0, (prev, r) => prev + (r['rating'] as int));
          avgRating = sum / ratingData.length;
        }

        members.add({
          'name': member['users']['nickname'] ?? '未知',
          'role': member['role'] == 'creator' ? '創建者' :
          member['role'] == 'driver' ? '司機' : '乘客',
          'rating': avgRating,
        });
      }

      if (mounted) {
        setState(() {
          _members = members;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('載入成員失敗: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
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
                    _buildDetailItem(Icons.my_location, '出發地', widget.trip.origin),
                    _buildDetailItem(Icons.flag, '目的地', widget.trip.destination),
                    _buildDetailItem(Icons.access_time, '出發時間', widget.trip.timeText),
                    _buildDetailItem(Icons.event_seat, '剩餘座位', widget.trip.seatsText),
                    _buildDetailItem(Icons.note, '備註', widget.trip.note.isEmpty ? '無' : widget.trip.note),
                    const SizedBox(height: 20),
                    _buildSectionTitle('成員列表'),
                    const SizedBox(height: 8),
                    // ✅ 顯示真實成員資料
                    ..._members.map((member) => Container(
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
                                member['rating'].toStringAsFixed(1),
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
//  3. 行程成員視窗 (JoinRequestsDialog)
// ==========================================
// ==========================================
//  3. 加入申請視窗 (JoinRequestsDialog)
// ==========================================
class JoinRequestsDialog extends StatefulWidget {
  final String tripId;

  const JoinRequestsDialog({
    super.key,
    required this.tripId,
  });

  @override
  State<JoinRequestsDialog> createState() => _JoinRequestsDialogState();
}

class _JoinRequestsDialogState extends State<JoinRequestsDialog> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  // ✅ 從 join_requests 載入待審核的申請
  Future<void> _loadRequests() async {
    setState(() => _loading = true);

    try {
      // ✅ 查詢待審核的申請
      final data = await supabase
          .from('join_requests')
          .select('''
            trip_id,
            user_id,
            created_at,
            users!join_requests_user_id_fkey(
              nickname
            )
          ''')
          .eq('trip_id', widget.tripId)
          .order('created_at', ascending: true);

      // ✅ 對每個申請者，查詢評分和違規記錄
      final requests = <Map<String, dynamic>>[];

      for (var req in data) {
        final userId = req['user_id'] as String;

        // 查詢平均評分
        final ratingData = await supabase
            .from('ratings')
            .select('rating')
            .eq('to_user', userId);

        double avgRating = 5.0;
        if (ratingData.isNotEmpty) {
          final sum = ratingData.fold<int>(0, (prev, r) => prev + (r['rating'] as int));
          avgRating = sum / ratingData.length;
        }

        // 查詢違規次數
        final violationData = await supabase
            .from('violations')
            .select('id')
            .eq('user_id', userId);

        requests.add({
          'user_id': userId,
          'name': req['users']['nickname'] ?? '未知',
          'rating': avgRating,
          'violation': violationData.length,
          'noShow': 0,
          'created_at': req['created_at'],
        });
      }

      if (mounted) {
        setState(() {
          _requests = requests;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('載入申請失敗: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ✅ 核准申請
  Future<void> _handleApprove(Map<String, dynamic> request) async {
    try {
      // 1️⃣ 把該用戶加入 trip_members
      await supabase.from('trip_members').insert({
        'trip_id': widget.tripId,
        'user_id': request['user_id'],
        'role': 'passenger',
        'join_time': DateTime.now().toIso8601String(),
      });

      // 2️⃣ 刪除申請記錄
      await supabase
          .from('join_requests')
          .delete()
          .eq('trip_id', widget.tripId)
          .eq('user_id', request['user_id']);

      // 3️⃣ 前端移除
      if (mounted) {
        setState(() {
          _requests.removeWhere((r) => r['user_id'] == request['user_id']);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已核准 ${request['name']} 的申請'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('核准失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('核准失敗: $e')),
        );
      }
    }
  }

  // ✅ 拒絕申請
  Future<void> _handleReject(Map<String, dynamic> request) async {
    try {
      // 直接刪除申請記錄
      await supabase
          .from('join_requests')
          .delete()
          .eq('trip_id', widget.tripId)
          .eq('user_id', request['user_id']);

      // 前端移除
      if (mounted) {
        setState(() {
          _requests.removeWhere((r) => r['user_id'] == request['user_id']);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已拒絕 ${request['name']} 的申請'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('拒絕失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拒絕失敗: $e')),
        );
      }
    }
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
                const Text('加入申請', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _requests.isEmpty
                  ? const Center(child: Text('目前沒有加入申請', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  final request = _requests[index];
                  return InkWell(
                    onTap: () => _showMemberProfile(request),
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
                                Text(request['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                    const SizedBox(width: 2),
                                    Text(
                                      request['rating'].toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // ✅ 核准按鈕（綠勾勾）
                          IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                            onPressed: () => _handleApprove(request),
                          ),
                          // ✅ 拒絕按鈕（紅叉叉）
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                            onPressed: () => _handleReject(request),
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