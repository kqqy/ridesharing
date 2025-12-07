import 'package:flutter/material.dart';

// ==========================================
//  1. 成員列表單項 (MemberListItem)
//  負責繪製單一成員的姓名、角色和在線狀態，並處理點擊事件。
// ==========================================
class MemberListItem extends StatelessWidget {
  final String role;
  final String name;
  final bool isOnline;
  final VoidCallback? onTap; 

  const MemberListItem({
    super.key,
    required this.role,
    required this.name,
    required this.isOnline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = isOnline ? Colors.green : Colors.grey;
    final String statusText = isOnline ? '在線' : '不在線';

    return InkWell( 
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
      ),
    );
  }
}


// ==========================================
//  2. UI 元件：成員詳細資訊視窗 (MemberDetailsDialog)
//  彈出視窗內容：違規、放鳥、評價、(司機專屬的車種車牌)。
// ==========================================
class MemberDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> details;

  const MemberDetailsDialog({super.key, required this.details});

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDriver = details['isDriver'] ?? false;
    final double rating = details['rating'] ?? 0.0;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Center(
        child: Text(
          details['name'] ?? '成員詳情',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 10),

            // 1. 違規/放鳥次數
            _buildInfoRow('違規次數', '${details['violations'] ?? 0} 次', valueColor: Colors.red),
            _buildInfoRow('放鳥次數', '${details['flakes'] ?? 0} 次', valueColor: Colors.red),
            const Divider(height: 20),

            // 2. 評價 (星等與星數)
            const Text('平均評價', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: [
                // 顯示五顆星星
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating.floor() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 24,
                    );
                  }),
                ),
                const SizedBox(width: 8),
                Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 20),

            // 3. 司機專屬資訊
            if (isDriver) ...[
              const Text('車輛資訊', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _buildInfoRow('車種', details['car_model'] ?? 'N/A'),
              _buildInfoRow('車牌', details['license_plate'] ?? 'N/A'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('關閉'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}

// ==========================================
//  3. UI 元件：成員列表主體 (MemberListBody)
//  負責整個頁面的 AppBar 和 ListView 佈局。
// ==========================================
class MemberListBody extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final Function(Map<String, dynamic> member) onTapMember; 

  const MemberListBody({
    super.key,
    required this.members,
    required this.onTapMember,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('行程成員', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return MemberListItem(
              role: member['role'],
              name: member['name'],
              isOnline: member['isOnline'],
              onTap: () => onTapMember(member),
            );
          },
        ),
      ),
    );
  }
}