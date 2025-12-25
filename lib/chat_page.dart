import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'member_list_page.dart';

final supabase = Supabase.instance.client;

class ChatPage extends StatefulWidget {
  final String tripId;

  const ChatPage({
    super.key,
    required this.tripId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;

  // ===== 假成員資料（先留，之後你會換成 trip_members）=====
  //傳送訊息未修復
  final List<Map<String, dynamic>> _tripMembers = const [
    {'name': '司機', 'role': '司機', 'isOnline': true},
    {'name': '乘客 A', 'role': '乘客', 'isOnline': true},
    {'name': '乘客 B', 'role': '乘客', 'isOnline': false},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ===============================
  // 讀取該行程的聊天訊息
  // ===============================
  Future<void> _fetchMessages() async {
    try {
      final data = await supabase
          .from('trip_messages')
          .select()
          .eq('trip_id', widget.tripId)
          .order('created_at');

      setState(() {
        _messages = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('fetch messages error: $e');
      setState(() => _loading = false);
    }
  }

  // ===============================
  // 傳送訊息
  // ===============================
  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('trip_messages').insert({
      'trip_id': widget.tripId,
      'user_id': user.id,
      'content': text,
    });

    _msgController.clear();
    await _fetchMessages();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ===============================
  // 成員列表
  // ===============================
  void _openMemberList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberListPage(members: _tripMembers),
      ),
    );
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '行程聊天室',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            onPressed: _openMemberList,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ===============================
  // 訊息列表
  // ===============================
  Widget _buildMessageList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          '尚無訊息，開始聊天吧！',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final currentUserId = supabase.auth.currentUser?.id;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final bool isMe = msg['user_id'] == currentUserId;

        final time = msg['created_at']
            .toString()
            .substring(11, 16); // HH:mm

        return _buildMessageBubble(
          text: msg['content'] ?? '',
          isMe: isMe,
          senderName: isMe ? null : '其他成員',
          time: time,
        );
      },
    );
  }

  // ===============================
  // 單則訊息泡泡
  // ===============================
  Widget _buildMessageBubble({
    required String text,
    required bool isMe,
    String? senderName,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe && senderName != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                senderName,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          Row(
            mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isMe)
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  child: Text(
                    time,
                    style:
                    const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
              Container(
                constraints: const BoxConstraints(maxWidth: 250),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue : Colors.white,
                  border:
                  isMe ? null : Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomRight:
                    isMe ? const Radius.circular(0) : null,
                    bottomLeft:
                    !isMe ? const Radius.circular(0) : null,
                  ),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    time,
                    style:
                    const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================
  // 輸入框
  // ===============================
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: '輸入訊息...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.send,
                  color: Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
