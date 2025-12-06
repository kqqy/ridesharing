import 'package:flutter/material.dart';

// ==========================================
//  UI 元件：歷史行程卡片
// ==========================================
class HistoricalTripCard extends StatelessWidget {
  final String date;
  final String origin;
  final String destination;
  final int memberCount; // 司機 + 乘客數量
  final VoidCallback onTap;

  const HistoricalTripCard({
    super.key,
    required this.date,
    required this.origin,
    required this.destination,
    required this.memberCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 日期
              Text(
                date,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const Divider(height: 16),

              // 2. 出發地與目的地
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.my_location, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(origin, style: const TextStyle(fontSize: 16))),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.arrow_right_alt, color: Colors.grey),
                  ),

                  const Icon(Icons.flag, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(destination, style: const TextStyle(fontSize: 16))),
                ],
              ),
              const SizedBox(height: 12),

              // 3. 成員統計
              Row(
                children: [
                  const Icon(Icons.people_alt, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '成員總數 (司機+乘客): $memberCount 人',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
//  UI 元件：歷史行程主體
// ==========================================
class PassengerHistoryBody extends StatelessWidget {
  final List<Map<String, dynamic>> historyTrips;
  final VoidCallback onStatsTap;
  final Function(Map<String, dynamic>) onCardTap;

  const PassengerHistoryBody({
    super.key,
    required this.historyTrips,
    required this.onStatsTap,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('歷史行程與統計', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 個人統計按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onStatsTap,
                icon: const Icon(Icons.bar_chart),
                label: const Text('個人統計', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            
            const SizedBox(height: 25),
            
            // 2. 行程卡片列表
            const Text(
              '已完成行程',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 15),

            ...historyTrips.map((trip) {
              return HistoricalTripCard(
                date: trip['date'],
                origin: trip['origin'],
                destination: trip['destination'],
                memberCount: trip['members'],
                onTap: () => onCardTap(trip),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}