import 'package:flutter/material.dart';
import 'member_list_widgets.dart'; // 引入 UI

class MemberListPage extends StatefulWidget {
  final List<Map<String, dynamic>> members; 

  const MemberListPage({super.key, required this.members});

  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {

  // 根據點擊的成員，返回其詳細假資料 (邏輯層)
  Map<String, dynamic> _getFakeMemberDetails(String name, String role) {
    if (role.contains('司機')) {
      return {
        'name': name,
        'isDriver': true,
        'violations': 1,
        'flakes': 0,
        'rating': 4.7,
        'car_model': 'Toyota Sienta',
        'license_plate': 'ABC-1234',
      };
    } else {
      // 乘客資料
      return {
        'name': name,
        'isDriver': false,
        'violations': 0,
        'flakes': 2,
        'rating': 4.9,
      };
    }
  }

  // 處理成員點擊事件 (邏輯層：呼叫彈窗)
  void _handleMemberTap(Map<String, dynamic> member) {
    // 1. 獲取詳細假資料
    final details = _getFakeMemberDetails(member['name'], member['role']);

    // 2. 彈出詳細視窗 (呼叫 UI 元件)
    showDialog(
      context: context,
      builder: (context) => MemberDetailsDialog(details: details),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MemberListBody(
      members: widget.members,
      onTapMember: _handleMemberTap, // 傳遞點擊處理函式給 UI
    );
  }
}