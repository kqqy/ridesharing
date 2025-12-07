import 'package:flutter/material.dart';

// ==========================================
//  UI 元件：五星評價顯示
//  [修改] 移除 MainAxisSize.min 以便 Row 佔據最大寬度
// ==========================================
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final int starCount;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.starCount = 5,
  });

  Widget buildStar(BuildContext context, int index) {
    IconData icon;
    Color color = Colors.amber;

    // 判斷星星的類型：滿星、半星或空星
    if (index >= rating) {
      icon = Icons.star_border;
    } else if (index > rating - 1 && index < rating) {
      icon = Icons.star_half;
    } else {
      icon = Icons.star;
    }
    
    return Icon(icon, color: color, size: 28);
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Row 包含星星和分數，讓外部的父元件（如 PassengerStatsBody 裡的 Column）來控制對齊
    return Row(
      // 保持 MainAxisSize 為 Max (預設)，讓 Row 佔滿寬度
      mainAxisAlignment: MainAxisAlignment.end, // [修改] 將星星和星數組合靠右對齊
      children: <Widget>[
        // 渲染五顆星星
        Row(
          children: List.generate(starCount, (index) {
            return buildStar(context, index);
          }),
        ),
        const SizedBox(width: 10),
        // 顯示星數
        Text(
          rating.toStringAsFixed(1), // 顯示一位小數
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ==========================================
//  UI 元件：個人統計主體
//  [修改] 調整平均評價的佈局，確保標題和星數能在同一行且星數靠右
// ==========================================
class PassengerStatsBody extends StatelessWidget {
  final int passengerTrips;
  final int driverTrips;
  final double averageRating;

  const PassengerStatsBody({
    super.key,
    required this.passengerTrips,
    required this.driverTrips,
    required this.averageRating,
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

            // 1. 乘客次數
            _buildStatRow(
              '當過幾次乘客',
              '$passengerTrips 次',
              Colors.blueGrey,
            ),
            const Divider(),

            // 2. 司機次數
            _buildStatRow(
              '當過幾次司機',
              '$driverTrips 次',
              Colors.blueGrey,
            ),
            const Divider(height: 30, thickness: 2),
            
            // 3. 平均評價 - 調整為 Row 排版
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 確保元素能分開對齊
              children: [
                const Text(
                  '平均評價',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                
                // 放入 StarRatingDisplay，它內部已設定靠右對齊 (MainAxisAlignment.end)
                StarRatingDisplay(rating: averageRating), 
              ],
            ),
            // 移除原本的 SizedBox(height: 15) 和單獨的 StarRatingDisplay
          ],
        ),
      ),
    );
  }
}