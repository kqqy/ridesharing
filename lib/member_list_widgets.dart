import 'package:flutter/material.dart';
import 'stats_page.dart'; // [新增] 引入個人統計頁面

// ==========================================
//  1. 成員列表單項 (MemberListItem)
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
//  [修改] 使用 Stack 在右上角加入「詳細資訊」按鈕
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
    
    // 使用 Dialog + Stack 自定義佈局
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          // 1. 主要內容區塊
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20), // Top padding 加大，避開右上按鈕
            child: Column(
              mainAxisSize: MainAxisSize.min, // 依內容高度
              children: [
                // 標題
                Center(
                  child: Text(
                    details['name'] ?? '成員詳情',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 10),

                // 內容資訊
                _buildInfoRow('違規次數', '${details['violations'] ?? 0} 次', valueColor: Colors.red),
                const Divider(height: 20),

                // 評價
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('平均評價', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
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

                // 司機資訊
                if (isDriver) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('車輛資訊', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('車種', details['car_model'] ?? 'N/A'),
                  _buildInfoRow('車牌', details['license_plate'] ?? 'N/A'),
                  const SizedBox(height: 20),
                ],

                // 關閉按鈕
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('關閉', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),

          // 2. [新增] 右上角「詳細資訊」按鈕
          Positioned(
            top: 10,
            right: 10,
            child: InkWell(
              onTap: () {
                Navigator.pop(context); // 先關閉 Dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatsPage()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: const Text(
                  '詳細資訊',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
//  3. UI 元件：成員列表主體 (MemberListBody)
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