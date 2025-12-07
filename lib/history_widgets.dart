import 'package:flutter/material.dart';

// ==========================================
//  UI 元件：歷史行程卡片
// ==========================================
class HistoricalTripCard extends StatelessWidget {
  final String date;
  final String time; 
  final String origin;
  final String destination;
  final List<String> membersList; 
  final VoidCallback onTap;

  const HistoricalTripCard({
    super.key,
    required this.date,
    required this.time,
    required this.origin,
    required this.destination,
    required this.membersList,
    required this.onTap,
  });

  // [修正] 移除了 Expanded，避免在 Row 中嵌套導致 Layout 錯誤
  // 因為時間字串很短，不需要佔滿剩餘空間
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min, // 讓 Row 只佔用需要的空間
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          text, 
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), 
          overflow: TextOverflow.ellipsis
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String membersString = membersList.join('、');
    
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
              // 1. 頂部：日期與時間
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  _buildInfoRow(Icons.schedule, time),
                ],
              ),
              const Divider(height: 16),

              // 2. 中間：出發地 -> 目的地
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

              // 3. 底部：成員
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.people_alt, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '成員: $membersString',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
//  UI 元件：歷史行程主體 (HistoryBody)
// ==========================================
class HistoryBody extends StatelessWidget { 
  final List<Map<String, dynamic>> historyTrips;
  final VoidCallback onStatsTap;
  final Function(Map<String, dynamic>) onCardTap;

  const HistoryBody({
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
            // 統計按鈕
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
            
            // 列表標題
            const Text(
              '歷史行程',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 15),

            // 列表內容
            ...historyTrips.map((trip) {
              return HistoricalTripCard(
                date: trip['date']?.toString() ?? '', 
                time: trip['time']?.toString() ?? '',
                origin: trip['origin']?.toString() ?? '',
                destination: trip['destination']?.toString() ?? '',
                membersList: (trip['members_list'] as List<dynamic>?)?.cast<String>() ?? ['無成員資料'], 
                onTap: () => onCardTap(trip),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}