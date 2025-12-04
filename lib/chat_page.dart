import 'package:flutter/material.dart';
import 'chat_widgets.dart'; // ✅ 引入新檔案

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  // 假資料：行程成員列表 (包含在線狀態)
  final List<Map<String, dynamic>> _tripMembers = const [
    {'name': '司機 (我)', 'role': '司機', 'isOnline': true},
    {'name': '乘客 1', 'role': '乘客', 'isOnline': true},
    {'name': '乘客 2', 'role': '乘客', 'isOnline': false},
  ];

  // 顯示成員列表視窗的函式
  void _showMemberListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MemberListDialog(members: _tripMembers),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      // 1. 上方橫幅 (AppBar)
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('聊天室', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // 右邊的成員列表圖示：點擊後彈出視窗
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: () => _showMemberListDialog(context), // 呼叫彈出視窗函式
          ),
        ],
      ),
      
      // 2. 聊天內容
      body: Column(
        children: [
          // 訊息列表區域
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- 假對話開始 ---
                _buildMessageBubble(text: '司機大哥你好，請問是在車站大門口等嗎？', isMe: false, senderName: '乘客 1', time: '14:00'),
                const SizedBox(height: 10),
                _buildMessageBubble(text: '對的，大門口右手邊的計程車招呼站這裡。', isMe: true, time: '14:01'),

                // 系統提示訊息
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                      child: const Text('乘客 2 已加入', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),

                _buildMessageBubble(text: '收到，我大概 5 分鐘後到！', isMe: false, senderName: '乘客 2', time: '14:05'),
                // --- 假對話結束 ---
              ],
            ),
          ),

          // 3. 下方輸入框區域
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: '輸入訊息...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFFF0F0F0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 20,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 18), onPressed: () {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 小工具：對話泡泡 (保留在 ChatPage 內，因為是主要 UI 邏輯) ---
  Widget _buildMessageBubble({
    required String text,
    required bool isMe,
    String? senderName,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(senderName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ),

              Container(
                constraints: const BoxConstraints(maxWidth: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue : Colors.white,
                  border: isMe ? null : Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                    bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(20),
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
                ),
              ),

              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}