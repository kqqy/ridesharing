import 'package:flutter/material.dart';

// ==========================================
//  UI 元件：五星評價顯示
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.end, 
      children: <Widget>[
        Row(
          children: List.generate(starCount, (index) {
            return buildStar(context, index);
          }),
        ),
        const SizedBox(width: 10),
        Text(
          rating.toStringAsFixed(1), 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ==========================================
//  UI 元件：個人統計主體 (通用)
// ==========================================
class StatsBody extends StatelessWidget { // [修改] 更名
  final int passengerTrips;
  final int driverTrips;
  final double averageRating;

  const StatsBody({
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
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                const Text(
                  '平均評價',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                StarRatingDisplay(rating: averageRating), 
              ],
            ),
          ],
        ),
      ),
    );
  }
}