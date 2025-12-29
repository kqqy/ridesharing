import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import 'trip_model.dart';
import 'passenger_widgets.dart';
import 'stats_page.dart';

final supabase = Supabase.instance.client;

// ==========================================
// 1️⃣ UpcomingBody
// ==========================================
class UpcomingBody extends StatelessWidget {
  final bool isDriver;
  final List<Trip> upcomingTrips;
  final Map<String, String> roleMap;
  final Function(Trip) onCancelTrip;
  final Function(Trip) onChatTrip;
  final Function(Trip) onDetailTap;
  final Function(Trip)? onDepartTrip;

  const UpcomingBody({
    super.key,
    required this.isDriver,
    required this.upcomingTrips,
    required this.roleMap,
    required this.onCancelTrip,
    required this.onChatTrip,
    required this.onDetailTap,
    this.onDepartTrip,
  });

  @override
  Widget build(BuildContext context) {
    if (upcomingTrips.isEmpty) {
      return _empty();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: upcomingTrips.length,
      itemBuilder: (context, index) {
        final trip = upcomingTrips[index];
        final role = roleMap[trip.id] ?? 'passenger';
        final isCreator = role == 'creator';

        final card = PassengerTripCard(
          trip: trip,
          onDetailTap: () => onDetailTap(trip),
          onJoin: null,
          onChat: () => onChatTrip(trip),
          cancelText: isCreator ? '取消行程' : '離開',
          onDepart: isCreator ? () => onDepartTrip?.call(trip) : null,
          onCancel: () => onCancelTrip(trip),
          hasNotification: isCreator,
        );

        if (!isCreator) return card;

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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _empty() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.departure_board, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              '目前沒有即將出發的行程',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
}

// ==========================================
// ✅ 2️⃣ MiniRouteMap（真的 GoogleMap，但禁止滑動/縮放）
//  - 會把出發/目的地 marker + 路徑 polyline 畫出來
//  - 會自動 fitBounds，地點再遠都看得到兩點
// ==========================================
class MiniRouteMap extends StatefulWidget {
  final String origin;
  final String destination;

  const MiniRouteMap({
    super.key,
    required this.origin,
    required this.destination,
  });

  @override
  State<MiniRouteMap> createState() => _MiniRouteMapState();
}

class _MiniRouteMapState extends State<MiniRouteMap> {
  GoogleMapController? _controller;

  LatLng? _o;
  LatLng? _d;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  bool _loading = true;
  bool _routeBuilt = false;

  // ✅ 這個 Key 是拿來打 Directions（畫路線）
  //    注意：要啟用 Directions API / Billing / Key restriction 要允許
  static const String _googleApiKey = 'AIzaSyCQjEBcgsPbLD14kXGPcG7UUvDyd4PlPH0';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// 給地名加「台灣」避免 NTU 這種模糊字串被帶去國外或錯點
  String _normalizeTaiwan(String s) {
    final t = s.trim();
    if (t.isEmpty) return t;

    // 你也可以改成更嚴格：強制加 ", Taiwan"
    final hasTaiwan = t.contains('台灣') || t.toLowerCase().contains('taiwan');
    return hasTaiwan ? t : '$t, 台灣';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _routeBuilt = false;

    try {
      final originText = _normalizeTaiwan(widget.origin);
      final destText = _normalizeTaiwan(widget.destination);

      final oLoc = await locationFromAddress(originText);
      final dLoc = await locationFromAddress(destText);

      _o = LatLng(oLoc.first.latitude, oLoc.first.longitude);
      _d = LatLng(dLoc.first.latitude, dLoc.first.longitude);

      _markers
        ..clear()
        ..add(Marker(
          markerId: const MarkerId('origin'),
          position: _o!,
          infoWindow: const InfoWindow(title: '出發地'),
        ))
        ..add(Marker(
          markerId: const MarkerId('dest'),
          position: _d!,
          infoWindow: const InfoWindow(title: '目的地'),
        ));

      // 嘗試拿 Directions 畫路線（取不到就直線）
      await _buildRoute();
    } catch (e) {
      debugPrint('MiniRouteMap load failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
      // controller 可能還沒 ready，onMapCreated 會再 fitBounds
    }
  }

  Future<void> _buildRoute() async {
    if (_routeBuilt) return;
    _routeBuilt = true;

    if (_o == null || _d == null) return;

    try {
      final polylinePoints = PolylinePoints();
      final result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: _googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(_o!.latitude, _o!.longitude),
          destination: PointLatLng(_d!.latitude, _d!.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        final pts = result.points.map((p) => LatLng(p.latitude, p.longitude)).toList();
        _polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId('route'),
            points: pts,
            width: 5,
          ));
      } else {
        // fallback：直線
        _polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId('line'),
            points: [_o!, _d!],
            width: 4,
          ));

        debugPrint('Directions points empty. status=${result.status} err=${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('MiniRouteMap buildRoute failed: $e');
      // fallback：直線
      if (_o != null && _d != null) {
        _polylines
          ..clear()
          ..add(Polyline(
            polylineId: const PolylineId('line'),
            points: [_o!, _d!],
            width: 4,
          ));
      }
    }
  }

  void _fitBounds(LatLng a, LatLng b) {
    final sw = LatLng(
      a.latitude < b.latitude ? a.latitude : b.latitude,
      a.longitude < b.longitude ? a.longitude : b.longitude,
    );
    final ne = LatLng(
      a.latitude > b.latitude ? a.latitude : b.latitude,
      a.longitude > b.longitude ? a.longitude : b.longitude,
    );

    _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 40),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 200,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_o == null || _d == null) {
      return Container(
        height: 200,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('地圖載入失敗（定位不到地址）', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: _o!, zoom: 13),
          onMapCreated: (c) {
            _controller = c;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitBounds(_o!, _d!);
            });
          },

          // ✅ 禁止互動：不能滑動、不能縮放、不能旋轉
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,

          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,

          markers: _markers,
          polylines: _polylines,
        ),
      ),
    );
  }
}

/// ==========================================
// 2️⃣ PassengerTripDetailsDialog（改成真的 GoogleMap 小地圖）
// ==========================================
class PassengerTripDetailsDialog extends StatefulWidget {
  final Trip trip;
  const PassengerTripDetailsDialog({super.key, required this.trip});

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

  Future<void> _loadMembers() async {
    try {
      final data = await supabase
          .from('trip_members')
          .select('user_id, role, users!trip_members_user_id_fkey(nickname)')
          .eq('trip_id', widget.trip.id);

      final members = <Map<String, dynamic>>[];

      for (final m in data) {
        final ratings = await supabase
            .from('ratings')
            .select('rating')
            .eq('to_user', m['user_id']);

        final avg = ratings.isEmpty
            ? 5.0
            : ratings.fold<int>(0, (p, r) => p + (r['rating'] as int)) / ratings.length;

        members.add({
          'name': (m['users']?['nickname'] ?? '未知').toString(),
          'role': m['role'] == 'creator'
              ? '創建者'
              : m['role'] == 'driver'
                  ? '司機'
                  : '乘客',
          'rating': avg,
        });
      }

      if (!mounted) return;
      setState(() {
        _members = members;
        _loading = false;
      });
    } catch (e) {
      debugPrint('load members failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('行程詳細資訊', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
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
                          // ✅ 真正 GoogleMap 小地圖（不可滑動）
                          MiniRouteMap(
                            origin: widget.trip.origin,
                            destination: widget.trip.destination,
                          ),

                          _section('行程資訊'),
                          _item(Icons.my_location, '出發地', widget.trip.origin),
                          _item(Icons.flag, '目的地', widget.trip.destination),
                          _item(Icons.access_time, '出發時間', widget.trip.timeText),
                          _item(Icons.event_seat, '剩餘座位', widget.trip.seatsText),
                          _item(Icons.note, '備註', widget.trip.note.isEmpty ? '無' : widget.trip.note),
                          const SizedBox(height: 20),

                          _section('成員列表'),
                          ..._members.map(_memberCard),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        ),
      );

  Widget _item(IconData i, String l, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(i, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            SizedBox(width: 70, child: Text('$l：')),
            Expanded(child: Text(v)),
          ],
        ),
      );

  Widget _memberCard(Map<String, dynamic> m) => Container(
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
              backgroundColor: m['role'] == '司機' ? Colors.blue[100] : Colors.orange[100],
              child: Icon(m['role'] == '司機' ? Icons.drive_eta : Icons.person),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(m['role'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text((m['rating'] as double).toStringAsFixed(1)),
          ],
        ),
      );
}

// ==========================================
// 3️⃣ JoinRequestsDialog（加入申請審核）
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

  Future<void> _loadRequests() async {
    setState(() => _loading = true);

    try {
      // 1️⃣ 一次載入所有申請
      final data = await supabase
          .from('join_requests')
          .select('''
          trip_id,
          user_id,
          role,
          created_at,
          users!join_requests_user_id_fkey(
            nickname
          )
        ''')
          .eq('trip_id', widget.tripId)
          .order('created_at', ascending: true);

      if (data.isEmpty) {
        if (mounted) {
          setState(() {
            _requests = [];
            _loading = false;
          });
        }
        return;
      }

      // 2️⃣ 收集所有 user_id
      final userIds = data.map((req) => req['user_id'] as String).toList();

      // 3️⃣ ✅ 批次查詢評分（使用 or）
      final orConditionsRating = userIds.map((id) => 'to_user.eq.$id').join(',');
      final allRatings = await supabase
          .from('ratings')
          .select('to_user, rating')
          .or(orConditionsRating);

      // 4️⃣ ✅ 批次查詢違規（使用 or）
      final orConditionsViolation = userIds.map((id) => 'user_id.eq.$id').join(',');
      final allViolations = await supabase
          .from('violations')
          .select('user_id, id')
          .or(orConditionsViolation);

      // 5️⃣ 整理成 Map
      final ratingsMap = <String, List<int>>{};
      for (var rating in allRatings) {
        final userId = rating['to_user'] as String;
        ratingsMap.putIfAbsent(userId, () => []);
        ratingsMap[userId]!.add(rating['rating'] as int);
      }

      final violationsMap = <String, int>{};
      for (var violation in allViolations) {
        final userId = violation['user_id'] as String;
        violationsMap[userId] = (violationsMap[userId] ?? 0) + 1;
      }

      // 6️⃣ 組合最終結果
      final requests = <Map<String, dynamic>>[];

      for (var req in data) {
        final userId = req['user_id'] as String;
        final role = req['role'] as String? ?? 'passenger';
        final nickname = req['users']['nickname'] ?? '未知';

        final userRatings = ratingsMap[userId] ?? [];
        double avgRating = 5.0;
        if (userRatings.isNotEmpty) {
          avgRating = userRatings.reduce((a, b) => a + b) / userRatings.length;
        }

        final violationCount = violationsMap[userId] ?? 0;

        requests.add({
          'user_id': userId,
          'name': nickname,
          'role': role,
          'rating': avgRating,
          'violation': violationCount,
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
      debugPrint('載入加入申請失敗: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ✅ 這裡！替換整個 _handleApprove 方法
  Future<void> _handleApprove(Map<String, dynamic> request) async {
    try {
      final userId = request['user_id'];
      final role = request['role'] ?? 'passenger'; // ✅ 讀取 role

      debugPrint('========================================');
      debugPrint('✅ 核准加入申請');
      debugPrint('user_id: $userId');
      debugPrint('role: $role');

      // 1️⃣ 加入 trip_members（使用正確的 role）
      await supabase.from('trip_members').insert({
        'trip_id': widget.tripId,
        'user_id': userId,
        'role': role, // ✅ 使用申請時的 role
        'join_time': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ 已加入 trip_members，role: $role');

      // 2️⃣ 刪除申請
      await supabase
          .from('join_requests')
          .delete()
          .eq('trip_id', widget.tripId)
          .eq('user_id', userId);

      debugPrint('✅ 已刪除 join_requests');
      debugPrint('========================================');

      if (mounted) {
        setState(() {
          _requests.removeWhere((r) => r['user_id'] == userId);
        });

        final roleText = role == 'driver' ? '（司機）' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已核准 ${request['name']} $roleText 加入')),
        );
      }
    } catch (e) {
      debugPrint('========================================');
      debugPrint('❌ 核准失敗: $e');
      debugPrint('========================================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('核准失敗: $e')),
        );
      }
    }
  }

  Future<void> _handleReject(Map<String, dynamic> request) async {
    try {
      final userId = request['user_id'];

      await supabase
          .from('join_requests')
          .delete()
          .eq('trip_id', widget.tripId)
          .eq('user_id', userId);

      if (mounted) {
        setState(() {
          _requests.removeWhere((r) => r['user_id'] == userId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已拒絕 ${request['name']} 的申請')),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
            maxHeight: MediaQuery
                .of(context)
                .size
                .height * 0.6),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('加入申請',
                    style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                  ? const Center(
                  child: Text('目前沒有待審核的申請',
                      style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  final request = _requests[index];
                  final isDriver = request['role'] == 'driver'; // ✅ 判斷是否為司機

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDriver
                            ? Colors.blue.shade200 // ✅ 司機用藍色邊框
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: isDriver
                              ? Colors.blue[100] // ✅ 司機用藍色
                              : Colors.orange[100],
                          child: Icon(
                            isDriver ? Icons.drive_eta : Icons.person,
                            // ✅ 司機用車子圖示
                            color: isDriver ? Colors.blue : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    request['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  if (isDriver) ...[ // ✅ 司機標記
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius:
                                        BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '司機',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 14, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    request['rating']
                                        .toStringAsFixed(1),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '違規: ${request['violation']} 次',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: request['violation'] > 0
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green, size: 32),
                          onPressed: () => _handleApprove(request),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel,
                              color: Colors.red, size: 32),
                          onPressed: () => _handleReject(request),
                        ),
                      ],
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
// 4️⃣ MemberProfileDialog
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
                Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsPage()));
              },
              child: const Text(
                '詳細資料',
                style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold),
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
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ==========================================
// 5️⃣ PassengerManifestDialog
// ==========================================
class PassengerManifestDialog extends StatefulWidget {
  final List<Map<String, String>> members; // [{'id': '...', 'name': '...'}]
  final Function(Map<String, int>) onConfirm;

  const PassengerManifestDialog({
    super.key,
    required this.members,
    required this.onConfirm,
  });

  @override
  State<PassengerManifestDialog> createState() => _PassengerManifestDialogState();
}

class _PassengerManifestDialogState extends State<PassengerManifestDialog> {
  late Map<String, int> _status; // userId -> status (0:none, 1:arrived, 2:missing)

  @override
  void initState() {
    super.initState();
    _status = {for (var m in widget.members) m['id']!: 0};
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
            const Text('確認成員是否到達', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('被標記為未到達的成員將會被記錄違規', style: TextStyle(fontSize: 14, color: Colors.red)),
            const Divider(),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView(
                shrinkWrap: true,
                children: widget.members.map((m) {
                  final id = m['id']!;
                  final name = m['name']!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Row(
                          children: [
                            _buildStatusBtn('已到達', id, 1, Colors.green),
                            const SizedBox(width: 10),
                            _buildStatusBtn('未到達', id, 2, Colors.red),
                          ],
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: () => widget.onConfirm(_status),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text('確定出發', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBtn(String label, String id, int val, Color color) {
    final isSelected = _status[id] == val;
    return InkWell(
      onTap: () => setState(() => _status[id] = val),
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
// 6️⃣ DriverManifestDialog
// ==========================================
class DriverManifestDialog extends StatefulWidget {
  final List<String> passengers;
  final VoidCallback onConfirm;

  const DriverManifestDialog({
    super.key,
    required this.passengers,
    required this.onConfirm,
  });

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
                children: widget.passengers
                    .map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  _buildStatusBtn('已上車', p, 1, Colors.green),
                                  const SizedBox(width: 10),
                                  _buildStatusBtn('未出現', p, 2, Colors.red),
                                ],
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
                ElevatedButton(
                  onPressed: widget.onConfirm,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text('確認出發'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBtn(String label, String p, int val, Color color) {
    final isSelected = _status[p] == val;
    return InkWell(
      onTap: () => setState(() => _status[p] = val),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
