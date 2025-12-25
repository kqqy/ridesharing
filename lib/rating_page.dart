import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rating_widgets.dart';

final supabase = Supabase.instance.client;

class RatingPage extends StatefulWidget {
  final String tripId;

  const RatingPage({
    super.key,
    required this.tripId,
  });

  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  List<Map<String, dynamic>> _targets = [];
  bool _loading = true;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _fetchTripData();
  }

  @override
  void dispose() {
    for (var target in _targets) {
      target['controller']?.dispose();
    }
    super.dispose();
  }

  // ===============================
  // 功能：抓取行程中的真實成員
  // ===============================
  Future<void> _fetchTripData() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // 1. 取得行程資訊 (為了拿 driver_id)
      final tripData = await supabase
          .from('trips')
          .select('driver_id')
          .eq('id', widget.tripId)
          .single();
      
      final String driverId = tripData['driver_id'];
      _driverId = driverId; // 儲存 driverId 供提交時判斷

      List<Map<String, dynamic>> tempTargets = [];

      // 2. 處理司機 (如果自己不是司機)
      if (currentUserId != driverId) {
        final driverProfile = await supabase
            .from('profiles')
            .select('name')
            .eq('id', driverId)
            .maybeSingle();
        
        tempTargets.add({
          'user_id': driverId,
          'name': driverProfile?['name'] ?? '司機',
          'role': '司機',
          'rating': 5,
          'controller': TextEditingController(),
        });
      }

      // 3. 處理其他乘客
      final passengersData = await supabase
          .from('trip_members')
          .select('user_id, profiles(name)')
          .eq('trip_id', widget.tripId);
      
      for (var p in passengersData) {
        final pId = p['user_id'] as String;
        if (pId == currentUserId || pId == driverId) continue;

        final pName = p['profiles']?['name'] ?? '乘客';
        tempTargets.add({
          'user_id': pId,
          'name': pName,
          'role': '乘客',
          'rating': 5,
          'controller': TextEditingController(),
        });
      }

      if (mounted) {
        setState(() {
          _targets = tempTargets;
          _loading = false;
        });
      }

    } catch (e) {
      debugPrint('Error fetching rating targets: $e');
      if (mounted) {
        setState(() => _loading = false);
        // 失敗時的備用假資料
        _targets = [
           {'user_id': 'fake_1', 'name': '司機 (範例)', 'role': '司機', 'rating': 5, 'controller': TextEditingController()},
        ];
      }
    }
  }

  void _updateRating(int index, int newRating) {
    setState(() {
      _targets[index]['rating'] = newRating;
    });
  }

  // ===============================
  // 功能：將評價資料傳入資料庫
  // ===============================
  Future<void> _handleSubmit() async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    // 檢查是否為假資料/Demo 模式
    final bool isFakeTrip = widget.tripId.contains('fake');
    final bool hasFakeTarget = _targets.any((t) => t['user_id'] == 'fake_1');

    if (isFakeTrip || hasFakeTarget) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo 模式：已模擬送出評價')),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
      return;
    }

    try {
      // 1. 寫入 ratings 表
      final List<Map<String, dynamic>> ratingRows = _targets.map((t) {
        String type;
        if (currentUserId == _driverId) {
          type = 'driver_to_passenger';
        } else if (t['user_id'] == _driverId) {
          type = 'passenger_to_driver';
        } else {
          type = 'passenger_to_passenger';
        }

        return {
          'trip_id': widget.tripId,
          'from_user': currentUserId,
          'to_user': t['user_id'],
          'rating': t['rating'],
          'comment': t['controller'].text.trim(),
          'rating_type': type,
        };
      }).toList();

      if (ratingRows.isNotEmpty) {
        await supabase.from('ratings').insert(ratingRows);
      }

      // 2. 更新行程狀態 (僅限司機)
      // 避免乘客嘗試更新狀態而被 RLS 擋下導致錯誤
      if (currentUserId == _driverId) {
        await supabase
            .from('trips')
            .update({'status': 'completed'})
            .eq('id', widget.tripId);
      }

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      
    } catch (e) {
      debugPrint('Rating submit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('評價送出失敗，請稍後再試')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 使用原本的 UI 元件，不變更其參數
    final List<Widget> cards = List.generate(_targets.length, (index) {
      final target = _targets[index];
      return RateMemberCard(
        name: target['name'],
        role: target['role'],
        currentRating: target['rating'],
        commentController: target['controller'],
        onRatingChanged: (val) => _updateRating(index, val),
      );
    });

    return RatingBody(
      ratingCards: cards,
      onSubmit: _handleSubmit,
    );
  }
}