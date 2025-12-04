import 'package:flutter/material.dart';

// ==========================================
//  1. 成員列表單項 (MemberListItem)
//  左邊角色，右邊在線狀態
// ==========================================
class MemberListItem extends StatelessWidget {
  final String role;
  final String name;
  final bool isOnline;

  const MemberListItem({
    super.key,
    required this.role,
    required this.name,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    // 根據是否在線決定顏色和文字
    final Color statusColor = isOnline ? Colors.green : Colors.grey;
    final String statusText = isOnline ? '在線' : '不在線';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左邊：角色與名字
          Row(
            children: [
              Text(
                role,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),

          // 右邊：在線狀態標示
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
//  2. 成員列表視窗 (MemberListDialog)
// ==========================================
class MemberListDialog extends StatelessWidget {
  final List<Map<String, dynamic>> members;

  const MemberListDialog({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 450, maxWidth: 350),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題與關閉按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('成員列表', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            
            // 列表內容
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return MemberListItem(
                    role: member['role'],
                    name: member['name'],
                    isOnline: member['isOnline'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}