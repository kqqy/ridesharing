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

  Timer? _heartbeatTimer;
  Timer? _refreshTimer;
  RealtimeChannel? _messageChannel;  // ✅ 加上這個

  @override
  void initState() {
    super.initState();
    _startHeartbeat();
    _startRefreshTimer();
    _fetchMessages();
    _fetchMembers();
    _subscribeToMessages();  // ✅ 訂閱即時訊息
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _heartbeatTimer?.cancel();
    _refreshTimer?.cancel();
    _messageChannel?.unsubscribe();  // ✅ 取消訂閱
    super.dispose();
  }

  // ===============================
  // ✅ 訂閱即時訊息
  // ===============================
  void _subscribeToMessages() {
    debugPrint('========================================');
    debugPrint('📡 開始訂閱即時訊息');
    debugPrint('room_id: ${widget.tripId}');

    final channelName = 'chat_messages:${widget.tripId}';

    _messageChannel = supabase
        .channel(channelName)
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'chat_messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: widget.tripId,
      ),
      callback: (payload) {
        debugPrint('========================================');
        debugPrint('📨 收到 Realtime 事件');
        debugPrint('event: ${payload.eventType}');
        debugPrint('table: ${payload.table}');
        debugPrint('========================================');

        _fetchMessages();
      },
    )
        .subscribe((status, error) {
      debugPrint('========================================');
      debugPrint('📡 訂閱狀態變更: $status');
      if (error != null) {
        debugPrint('❌ 訂閱錯誤: $error');
      }
      debugPrint('========================================');
    });

    debugPrint('✅ 訂閱請求已發送');
    debugPrint('========================================');
  }

  // ===============================
  // 開始心跳
  // ===============================
  void _startHeartbeat() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _updateLastSeen(user.id);

    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _updateLastSeen(user.id),
    );
  }

  // ===============================
  // 更新 last_seen
  // ===============================
  Future<void> _updateLastSeen(String userId) async {
    try {
      await supabase
          .from('users')
          .update({'last_seen': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      debugPrint('❌ 更新 last_seen 失敗: $e');
    }
  }

  // ===============================
  // 開始定期刷新在線狀態
  // ===============================
  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _fetchMembers(),
    );
  }

  // ===============================
  // 判斷是否在線
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
  // 讀取訊息
  // ===============================
  Future<void> _fetchMessages() async {
    try {
      final data = await supabase
          .from('chat_messages')
          .select('''
          id,
          room_id,
          sender_id,
          message,
          created_at,
          users!chat_messages_sender_id_fkey(
            nickname
          )
        ''')
          .eq('room_id', widget.tripId)
          .order('created_at', ascending: true);

      debugPrint('✅ 載入 ${data.length} 則訊息');

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('❌ fetch messages error: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ===============================
  // 傳送訊息
  // ===============================
  // ===============================
// 傳送訊息
// ===============================
  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('❌ 未登入');
      return;
    }

    try {
      debugPrint('========================================');
      debugPrint('🎯 發送訊息: $text');

      // 更新 last_seen
      await _updateLastSeen(user.id);

      // 儲存訊息
      final messageText = text;

      // 清空輸入框
      _msgController.clear();

      // 發送訊息
      await supabase.from('chat_messages').insert({
        'room_id': widget.tripId,
        'sender_id': user.id,
        'message': messageText,
      });

      debugPrint('✅ 訊息已發送');

      // ✅ 立即刷新
      await _fetchMessages();

      debugPrint('========================================');
    } catch (e) {
      debugPrint('========================================');
      debugPrint('❌ 發送失敗: $e');
      debugPrint('========================================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發送失敗：$e')),
        );
      }
    }
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
        final bool isMe = msg['sender_id'] == currentUserId;

        String time;
        try {
          final createdAt = DateTime.parse(msg['created_at'] as String);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

          if (messageDate == today) {
            // 今天：只顯示時間
            time = '${createdAt.hour.toString().padLeft(2, '0')}:'
                '${createdAt.minute.toString().padLeft(2, '0')}';
          } else if (messageDate == today.subtract(const Duration(days: 1))) {
            // 昨天
            time = '昨天 ${createdAt.hour}:${createdAt.minute}';
          } else {
            // 更早
            time = '${createdAt.month}/${createdAt.day} ${createdAt.hour}:${createdAt.minute}';
          }
        } catch (e) {
          debugPrint('時間解析失敗: $e');
          time = '--:--';
        }

        final senderName = isMe
            ? null
            : (msg['users']?['nickname'] ?? '未知');

        return _buildMessageBubble(
          text: msg['message'] ?? '',
          isMe: isMe,
          senderName: senderName,
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
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                    bottomRight: isMe ? const Radius.circular(0) : null,
                    bottomLeft: !isMe ? const Radius.circular(0) : null,
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
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
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
              icon: const Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}