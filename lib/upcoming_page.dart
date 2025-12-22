import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'trip_model.dart';
import 'upcoming_widgets.dart';
import 'chat_page.dart';
import 'active_trip_page.dart';

final supabase = Supabase.instance.client;

class UpcomingPage extends StatefulWidget {
  final bool isDriver;

  const UpcomingPage({super.key, required this.isDriver});

  @override
  State<UpcomingPage> createState() => _UpcomingPageState();
}

class _UpcomingPageState extends State<UpcomingPage> {
  List<Trip> _upcomingTrips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUpcomingTrips();
  }

  // ===============================
  // 從 Supabase 撈即將出發行程
  // status: open / active
  // ===============================
  Future<void> _fetchUpcomingTrips() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('trips')
          .select()
          .or('status.eq.open,status.eq.active')
          .order('depart_time');

      final trips = (data as List).map<Trip>((e) {
        return Trip(
          id: e['id'].toString(),
          origin: e['origin'] ?? '',
          destination: e['destination'] ?? '',
          departTime: DateTime.parse(e['depart_time']),
          seatsTotal: e['seats_total'] ?? 0,
          seatsLeft: e['seats_left'] ?? 0,
          status: e['status'] ?? '',
          note: e['note'] ?? '',
        );
      }).toList();

      setState(() {
        _upcomingTrips = trips;
        _loading = false;
      });
    } catch (e) {
      debugPrint('fetch upcoming trips error: $e');
      setState(() => _loading = false);
    }
  }

  // ===============================
  // 取消 / 離開行程（目前只做 UI）
  // ===============================
  void _handleCancelTrip(Trip trip) {
    String title = widget.isDriver ? '確定取消行程？' : '⚠️ 退出警告';
    Widget content = widget.isDriver
        ? const Text('取消後將通知所有乘客，且無法復原。')
        : const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('若在六小時內退出，', style: TextStyle(fontSize: 16)),
        SizedBox(height: 5),
        Text(
          '將會有放鳥紀錄！',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: content,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('確定'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // ===============================
  // 行程聊天室
  // ===============================
  void _handleChatTrip(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) =>ChatPage(tripId: trip.id)),
    );
  }

  // ===============================
  // 乘客出發 → 進行中
  // ===============================
  void _handleDepartTrip(Trip trip) {
    final List<String> tripMembers = ['司機', '我 (乘客)', '乘客 B'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PassengerManifestDialog(
        members: tripMembers,
        onConfirm: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActiveTripPage(tripId: trip.id), // ✅ 關鍵
            ),
          );
        },
      ),
    );
  }

  // ===============================
  // 行程詳細資訊
  // ===============================
  void _handleTripDetail(Trip trip) {
    _showTripDetails(trip);
  }

  void _showTripDetails(Trip trip) {
    final List<Map<String, dynamic>> fakeMembers = [
      {'name': '王大明', 'role': '司機', 'rating': 4.9},
      {'name': '乘客 A', 'role': '乘客', 'rating': 5.0},
    ];

    showDialog(
      context: context,
      builder: (context) => PassengerTripDetailsDialog(
        trip: trip,
        members: fakeMembers,
      ),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return UpcomingBody(
      isDriver: widget.isDriver,
      upcomingTrips: _upcomingTrips,
      onCancelTrip: _handleCancelTrip,
      onChatTrip: _handleChatTrip,
      onDetailTap: _handleTripDetail,
      onDepartTrip: widget.isDriver ? null : _handleDepartTrip,
    );
  }
}
