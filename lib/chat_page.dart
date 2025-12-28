import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

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
  List<Map<String, dynamic>> _tripMembers = [];
  bool _loading = true;
  bool _loadingMembers = true;

  Timer? _heartbeatTimer;  // ✅ 心跳計時器
  Timer? _refreshTimer;    // ✅ 定期刷新在線狀態

  @override
  void initState() {
    super.initState();
    _startHeartbeat();    // ✅ 開始心跳
    _startRefreshTimer(); // ✅ 開始定期刷新
    _fetchMessages();
    _fetchMembers();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _heartbeatTimer?.cancel();  // ✅ 停止心跳
    _refreshTimer?.cancel();    // ✅ 停止刷新
    super.dispose();
  }

  // ===============================
  // ✅ 開始心跳（每 30 秒更新一次 last_seen）
  // ===============================
  void _startHeartbeat() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // 立即更新一次
    _updateLastSeen(user.id);

    // 每 30 秒更新一次
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _updateLastSeen(user.id),
    );
  }

  // ===============================
  // ✅ 更新 last_seen
  // ===============================
  Future<void> _updateLastSeen(String userId) async {
    try {
      await supabase
          .from('users')
          .update({'last_seen': DateTime.now().toIso8601String()})
          .eq('id', userId);
      debugPrint('✅ 更新 last_seen: $userId');
    } catch (e) {
      debugPrint('❌ 更新 last_seen 失敗: $e');
    }
  }

  // ===============================
  // ✅ 開始定期刷新在線狀態（每 30 秒）
  // ===============================
  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _fetchMembers(), // 重新載入成員（會更新在線狀態）
    );
  }

  // ===============================
  // ✅ 判斷是否在線（5 分鐘內算在線）
  // ===============================
  bool _isOnline(DateTime? lastSeen) {
    if (lastSeen == null) return false;
    final diff = DateTime.now().difference(lastSeen);
    return diff.inMinutes < 5;
  }

  // ===============================
  // 讀取行程成員
  // ===============================
  Future<void> _fetchMembers() async {
    try {
      final data = await supabase
          .from('trip_members')
          .select('''
            user_id,
            role,
            users!trip_members_user_id_fkey(
              nickname,
              last_seen
            )
          ''')
          .eq('trip_id', widget.tripId);

      final members = <Map<String, dynamic>>[];

      for (var member in data) {
        final userId = member['user_id'] as String;
        final nickname = member['users']['nickname'] ?? '未知';
        final role = member['role'] as String;
        final lastSeenStr = member['users']['last_seen'];

        String displayRole;
        if (role == 'creator') {
          displayRole = '創建者';
        } else if (role == 'driver') {
          displayRole = '司機';
        } else {
          displayRole = '乘客';
        }

        // ✅ 判斷在線狀態
        final lastSeen = lastSeenStr != null ? DateTime.parse(lastSeenStr) : null;
        final isOnline = _isOnline(lastSeen);

        members.add({
          'user_id': userId,
          'name': nickname,
          'role': displayRole,
          'isOnline': isOnline,
        });
      }

      if (mounted) {
        setState(() {
          _tripMembers = members;
          _loadingMembers = false;
        });
      }
    } catch (e) {
      debugPrint('fetch members error: $e');
      if (mounted) {
        setState(() => _loadingMembers = false);
      }
    }
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

    // ✅ 發送訊息時也更新 last_seen
    await _updateLastSeen(user.id);

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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                '${_tripMembers.where((m) => m['isOnline'] == true).length} 人在線',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
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
            .substring(11, 16);

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