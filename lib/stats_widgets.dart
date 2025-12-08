import 'package:flutter/material.dart';

// ==========================================
//  UI 元件：五星評價顯示 (大)
// ==========================================
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int starCount;
  final double iconSize; // [新增] 可調整大小

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.starCount = 5,
    this.iconSize = 28,
  });

  Widget buildStar(BuildContext context, int index) {
    IconData icon;
    Color color = Colors.amber;

    if (index >= rating) {
      icon = Icons.star_border;
    } else if (index > rating - 1 && index < rating) {
      icon = Icons.star_half;
    } else {
      icon = Icons.star;
    }
    
    return Icon(icon, color: color, size: iconSize);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: List.generate(starCount, (index) {
            return buildStar(context, index);
          }),
        ),
      ],
    );
  }
}

// ==========================================
//  UI 元件：單則評論卡片 [新增]
// ==========================================
class ReviewCard extends StatelessWidget {
  final String name;
  final int rating;
  final String comment;

  const ReviewCard({
    super.key,
    required this.name,
    required this.rating,
    required this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                // 顯示該評論的星星
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 18,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment,
              style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
//  UI 元件：個人統計主體 (StatsBody)
// ==========================================
class StatsBody extends StatelessWidget { 
  final int passengerTrips;
  final int driverTrips;
  final double averageRating;
  final List<Map<String, dynamic>> reviews; // [新增] 接收評論資料

  const StatsBody({
    super.key,
    required this.passengerTrips,
    required this.driverTrips,
    required this.averageRating,
    required this.reviews, // [新增]
  });

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('個人統計', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '行程次數統計',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Divider(height: 30, thickness: 2),

            _buildStatRow(
              '當過幾次乘客',
              '$passengerTrips 次',
              Colors.blueGrey,
            ),
            const Divider(),

            _buildStatRow(
              '當過幾次司機',
              '$driverTrips 次',
              Colors.blueGrey,
            ),
            const Divider(height: 30, thickness: 2),
            
            // 平均評價區塊
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                const Text(
                  '平均評價',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                Row(
                  children: [
                    StarRatingDisplay(rating: averageRating),
                    const SizedBox(width: 8),
                    Text(
                      averageRating.toStringAsFixed(1), 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // [新增] 近期評論區塊
            const Text(
              '近期評論',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 15),
            
            // 評論列表
            ...reviews.map((r) => ReviewCard(
              name: r['name'],
              rating: r['rating'],
              comment: r['comment'],
            )),
          ],
        ),
      ),
    );
  }
}