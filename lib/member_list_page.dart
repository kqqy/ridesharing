import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class MemberListPage extends StatefulWidget {
  final List<Map<String, dynamic>> members;

  const MemberListPage({
    super.key,
    required this.members,
  });

  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {
  Map<String, Map<String, dynamic>> _memberStats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMemberStats();
  }

  Future<void> _loadMemberStats() async {
    try {
      debugPrint('========================================');
      debugPrint('📊 開始載入成員統計資料');

      final Map<String, Map<String, dynamic>> stats = {};

      for (var member in widget.members) {
        final userId = member['user_id'] as String;
        final role = member['role'] as String? ?? '乘客';

        debugPrint('載入 user_id: $userId 的資料');
        debugPrint('角色: $role');

        // 1️⃣ 查詢違規次數
        final violationsData = await supabase
            .from('violations')
            .select('id')
            .eq('user_id', userId);

        final violationCount = violationsData.length;

        // 2️⃣ 查詢評價
        final ratingsData = await supabase
            .from('ratings')
            .select('rating')
            .eq('to_user', userId);

        double avgRating = 0.0;
        if (ratingsData.isNotEmpty) {
          final totalScore = ratingsData.fold<double>(
            0.0,
                (sum, r) => sum + (r['rating'] as num).toDouble(),
          );
          avgRating = totalScore / ratingsData.length;
        }

        stats[userId] = {
          'violation_count': violationCount,
          'average_rating': avgRating,
          'rating_count': ratingsData.length,
        };

        debugPrint('  違規次數: $violationCount');
        debugPrint('  平均評分: ${avgRating.toStringAsFixed(1)}');
        debugPrint('  評價數量: ${ratingsData.length}');
      }

      debugPrint('✅ 成員統計資料載入完成');
      debugPrint('========================================');

      if (mounted) {
        setState(() {
          _memberStats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('========================================');
      debugPrint('❌ 載入成員統計失敗: $e');
      debugPrint('========================================');

      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMemberDetail(Map<String, dynamic> member) {
    final userId = member['user_id'] as String;
    final stats = _memberStats[userId];

    if (stats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('載入資料中，請稍後再試')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => MemberDetailDialog(
        member: member,
        violationCount: stats['violation_count'] as int,
        averageRating: stats['average_rating'] as double,
        ratingCount: stats['rating_count'] as int,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('行程成員'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.members.length,
        itemBuilder: (context, index) {
          final member = widget.members[index];
          final isOnline = member['isOnline'] as bool? ?? false;
          final role = member['role'] as String? ?? '乘客';  // ✅ 取得角色

          debugPrint('顯示成員: ${member['name']}, 角色: $role');

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      member['name'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Row(
                children: [
                  Text(
                    member['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ✅ 角色標籤
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(role),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                isOnline ? '在線' : '離線',
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.grey,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showMemberDetail(member),
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    debugPrint('角色顏色判斷: $role');

    switch (role) {
      case '創建者':
        return Colors.purple;
      case '司機':
        return Colors.blue;
      case '乘客':
        return Colors.orange;
      default:
        debugPrint('⚠️ 未知角色: $role，使用預設顏色');
        return Colors.grey;
    }
  }
}

// ==========================================
//  成員詳細資訊對話框
// ==========================================
class MemberDetailDialog extends StatelessWidget {
  final Map<String, dynamic> member;
  final int violationCount;
  final double averageRating;
  final int ratingCount;

  const MemberDetailDialog({
    super.key,
    required this.member,
    required this.violationCount,
    required this.averageRating,
    required this.ratingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 標題
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  member['name'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('關閉'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // 違規次數
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '違規次數',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  '$violationCount 次',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: violationCount > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 平均評價
            const Text(
              '平均評價',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // 星星顯示
            if (ratingCount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  if (index < averageRating.floor()) {
                    return const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 32,
                    );
                  } else if (index < averageRating.ceil() &&
                      averageRating % 1 != 0) {
                    return const Icon(
                      Icons.star_half,
                      color: Colors.amber,
                      size: 32,
                    );
                  } else {
                    return const Icon(
                      Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    );
                  }
                }),
              ),
              const SizedBox(height: 8),
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                '共 $ratingCount 則評價',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.star_border,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 8),
              const Text(
                '尚無評價',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}