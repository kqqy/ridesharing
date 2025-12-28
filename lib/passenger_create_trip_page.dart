import 'package:flutter/material.dart';
import 'passenger_create_trip_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'violation_service.dart'; // Import ViolationService

final supabase = Supabase.instance.client;

class PassengerCreateTripPage extends StatefulWidget {
  const PassengerCreateTripPage({super.key});

  @override
  State<PassengerCreateTripPage> createState() => _PassengerCreateTripPageState();
}

class _PassengerCreateTripPageState extends State<PassengerCreateTripPage> {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _seatsController =
      TextEditingController(text: '4'); // 預設固定 4
  final TextEditingController _noteController = TextEditingController();

  DateTime? _selectedDepartTime;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _timeController.dispose();
    _seatsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleTimePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null) return;

    final selected = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final String formattedStr =
        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')} "
        "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";

    setState(() {
      _selectedDepartTime = selected;
      _timeController.text = formattedStr;
    });
  }

  Future<void> _handleSubmit() async {
    // ✅ 0) 檢查停權狀態
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      final isSuspended = await ViolationService().isUserSuspended(currentUser.id);
      if (isSuspended) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('您的帳號目前已被停權，無法建立行程。'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final String origin = _originController.text.trim();
    final String destination = _destinationController.text.trim();
    final String note = _noteController.text.trim();

    if (origin.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫出發地與目的地')),
      );
      return;
    }

    final DateTime? departTime = _selectedDepartTime;
    if (departTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇出發時間')),
      );
      return;
    }

    final int seatsTotal = int.tryParse(_seatsController.text.trim()) ?? 4;

    // ✅ 1) 取得目前登入者
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入再建立行程')),
      );
      return;
    }
    final String creatorId = user.id;

    try {
      // ✅ 2) 保險：先確保 public.users 有這個人（避免 trips 外鍵炸掉）
      // 依你的表結構：users 有 nickname / email / phone（phone 若沒有就不寫）
      final String fallbackNickname =
      (user.email?.split('@').first ?? 'user').trim();

      await supabase.from('users').upsert({
        'id': creatorId,
        if (user.email != null) 'email': user.email,
        'nickname': fallbackNickname,
        // phone 你如果要寫，這裡需要你有 phone 來源（通常註冊時存）
      });

      // ✅ 3) 寫入 trips
      final inserted = await supabase
          .from('trips')
          .insert({
            'creator_id': creatorId,
            'origin': origin,
            'destination': destination,
            'depart_time': departTime.toIso8601String(),
            'seats_total': seatsTotal,
            'seats_left': seatsTotal,
            'status': 'open',
            'note': note,
          })
          .select('id')
          .single();

      final String tripId = inserted['id'] as String;
      // ✅ 4) 把創建者也加入 trip_members，role 設為 creator
      await supabase.from('trip_members').insert({
        'trip_id': tripId,
        'user_id': creatorId,
        'role': 'creator',  // ✅✅✅ 改成 creator
        'join_time': DateTime.now().toIso8601String(),
      });


      if (!mounted) return;
      Navigator.pop(context, tripId); // ✅ 回傳 tripId 給上一頁
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('建立行程失敗（DB）：${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('建立行程失敗：$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PassengerCreateTripForm(
      originController: _originController,
      destinationController: _destinationController,
      timeController: _timeController,
      seatsController: _seatsController,
      noteController: _noteController,
      onTimeTap: _handleTimePicker,
      onSubmit: _handleSubmit,
    );
  }
}
