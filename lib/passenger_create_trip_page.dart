import 'package:flutter/material.dart';
import 'passenger_create_trip_widgets.dart'; // 引入 UI

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

    final String formattedStr = 
        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')} "
        "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";

    setState(() {
      _timeController.text = formattedStr;
    });
  }

  // [修改] 處理送出：不檢查內容，不跳提示，直接關閉
  void _handleSubmit() {
    // 您說只要 UI 介面完善，不需要檢查完整性，也不要提示
    // 直接關閉頁面並回傳 true
    Navigator.pop(context, true);
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