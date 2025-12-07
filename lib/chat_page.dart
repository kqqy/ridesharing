import 'package:flutter/material.dart';
import 'chat_widgets.dart'; // 引入新的 UI 主體
import 'member_list_page.dart'; // 引入成員列表頁面

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  // 假資料：行程成員列表 (包含在線狀態) - 保留在邏輯層
  final List<Map<String, dynamic>> _tripMembers = const [
    {'name': '司機 (我)', 'role': '司機', 'isOnline': true},
    {'name': '乘客 1', 'role': '乘客', 'isOnline': true},
    {'name': '乘客 2', 'role': '乘客', 'isOnline': false},
  ];

  // 處理點擊成員列表按鈕的邏輯 (導航)
  void _handleMemberListTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberListPage(members: _tripMembers), // 導航到新頁面
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 將所有數據和邏輯傳遞給 ChatBody
    return ChatBody(
      tripMembers: _tripMembers,
      onMemberListTap: () => _handleMemberListTap(context),
    );
  }
}