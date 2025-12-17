import 'package:flutter/material.dart';
import 'passenger_create_trip_widgets.dart'; // 引入 UI
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
class PassengerCreateTripPage extends StatefulWidget {
  const PassengerCreateTripPage({super.key});

  @override
  State<PassengerCreateTripPage> createState() => _PassengerCreateTripPageState();
}

class _PassengerCreateTripPageState extends State<PassengerCreateTripPage> {
  // 建立控制器
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController(text: '4'); // 預設固定為 4
  final TextEditingController _noteController = TextEditingController();
  DateTime? _selectedDepartTime; // ✅ 真正要寫進資料庫的時間


  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _timeController.dispose();
    _seatsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // 處理時間選擇
Future<void> _handleTimePicker() async {
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime.now(),
    lastDate: DateTime(2100),
  );

  if (pickedDate == null) return;
  if (!mounted) return;

  TimeOfDay? pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );

  if (pickedTime == null) return;

  // ✅ 這個才是「真正的時間」，之後 insert 會用它
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
    _selectedDepartTime = selected;   // ✅ 多存這行（重點）
    _timeController.text = formattedStr;
  });
}


    // [修改] 處理送出：不檢查內容，不跳提示，直接關閉
  Future<void> _handleSubmit() async {
    // 1️⃣ 讀取輸入欄位
    final String origin = _originController.text.trim();
    final String destination = _destinationController.text.trim();
    final String note = _noteController.text.trim();

    // 2️⃣ 基本檢查（出發地 / 目的地）
    if (origin.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫出發地與目的地')),
      );
      return;
    }

    // 3️⃣ 檢查是否有選擇時間
    final DateTime? departTime = _selectedDepartTime;
    if (departTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇出發時間')),
      );
      return;
    }

    // 4️⃣ 座位數（從 TextField 轉成 int）
    final int seatsTotal =
        int.tryParse(_seatsController.text.trim()) ?? 4;

    // 5️⃣ 目前先用固定 creator_id（之後可換成 auth）
    const String creatorId = '11111111-1111-1111-1111-111111111111';

    try {
      // 6️⃣ 寫入 Supabase trips
      await supabase.from('trips').insert({
        'creator_id': creatorId,
        'origin': origin,
        'destination': destination,
        'depart_time': departTime.toIso8601String(),
        'seats_total': seatsTotal,
        'seats_left': seatsTotal,
        'status': 'open',
        'note': note,
      });

      // 7️⃣ 成功後回到上一頁
      if (!mounted) return;
      Navigator.pop(context, true);

    } catch (e) {
      // 8️⃣ 失敗處理
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('建立行程失敗：$e')),
      );
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