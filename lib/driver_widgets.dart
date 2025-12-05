import 'package:flutter/material.dart';
import 'trip_model.dart'; // 引入資料結構

// ==========================================
//  UI 元件：緊湊型輸入框 (CompactTextField)
// ==========================================
class CompactTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isNumber;
  final bool readOnly;
  final VoidCallback? onTap;

  const CompactTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isNumber = false,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
    );
  }
}

// ==========================================
//  UI 元件：乘客列表單項 (PassengerListItem)
//  負責顯示名字、星等、和詳細按鈕
// ==========================================
class PassengerListItem extends StatelessWidget {
  final String name;
  final int rating;
  final VoidCallback onTapDetails; // 點擊詳細按鈕的回呼

  const PassengerListItem({
    super.key,
    required this.name,
    required this.rating,
    required this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
          SizedBox(
            height: 30,
            child: OutlinedButton(
              onPressed: onTapDetails,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('詳細', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
//  3. 行程卡片 (TripCard)
//  負責顯示單一行程資訊和三個按鈕
// ==========================================
class TripCard extends StatelessWidget {
  final Trip trip;
  final Function(String) onMenuSelected; // 菜單點擊回呼
  final VoidCallback onDepart; // 出發按鈕回呼
  final VoidCallback onChat; // 聊天室按鈕回呼

  const TripCard({
    super.key,
    required this.trip,
    required this.onMenuSelected,
    required this.onDepart,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.my_location, '出發：${trip.origin}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.flag, '目的：${trip.destination}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, '時間：${trip.time}'),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.event_seat, '剩餘座位：${trip.seats}'),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: onMenuSelected,
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem(value: '行程備註', child: Text('行程備註')),
                  const PopupMenuItem(value: '編輯行程', child: Text('編輯行程')),
                  const PopupMenuItem(value: '乘客管理', child: Text('乘客管理')),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onDepart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('出發'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: onChat,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('聊天室'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ==========================================
//  4. 乘客管理視窗內容 (包含開關和按鈕)
// ==========================================
class PassengerManagementContent extends StatelessWidget {
  final bool isAutoApprove;
  final ValueChanged<bool> onSwitchToggle;
  final VoidCallback onListTap;

  const PassengerManagementContent({
    super.key,
    required this.isAutoApprove,
    required this.onSwitchToggle,
    required this.onListTap,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // 選項 1: 自動審核 (開關)
        SwitchListTile(
          title: const Text('自動審核', style: TextStyle(fontSize: 16)),
          value: isAutoApprove,
          activeColor: Colors.blue,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          onChanged: onSwitchToggle,
        ),
        
        // 選項 2: 乘客清單 (按鈕)
        SimpleDialogOption(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          onPressed: onListTap,
          child: const Text('乘客清單', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}

// ==========================================
//  5. 繪製三角形 (Popover箭頭)
// ==========================================
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(size.width / 2, 0); path.lineTo(0, size.height); path.lineTo(size.width, size.height); path.close();
    canvas.drawShadow(path, Colors.black.withOpacity(0.1), 2.0, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
//  6. SOS 視窗 (純介面)
// ==========================================
class SOSCountdownDialog extends StatelessWidget {
  const SOSCountdownDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Center(
        child: Text(
          '確定要撥打求救電話?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '倒數 2 秒', 
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('確定'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('取消'),
            ),
          ],
        ),
      ],
    );
  }
}

// ==========================================
//  7. 乘客評價卡片
// ==========================================
class RatePassengerCard extends StatefulWidget {
  final String name;
  final int initialRating;
  final int passengerIndex;

  const RatePassengerCard({
    super.key,
    required this.name,
    required this.initialRating,
    required this.passengerIndex,
  });

  @override
  State<RatePassengerCard> createState() => _RatePassengerCardState();
}

class _RatePassengerCardState extends State<RatePassengerCard> {
  int _rating = 5; 
  bool _isPolite = true;
  bool _isPunctual = true;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating; 
  }

  Widget _buildToggleRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Row(
          children: [
            // 是
            Checkbox(
              value: value,
              onChanged: (newValue) => onChanged(true),
              activeColor: Colors.green,
            ),
            const Text('是'),
            const SizedBox(width: 10),
            // 否
            Checkbox(
              value: !value,
              onChanged: (newValue) => onChanged(false),
              activeColor: Colors.red,
            ),
            const Text('否'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 姓名與星等
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // 星等顯示與點擊
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        child: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const Divider(height: 20),

            // 1. 是否準時 (Checkboxes)
            _buildToggleRow('是否準時', _isPunctual, (val) => setState(() => _isPunctual = val)),
            const SizedBox(height: 10),

            // 2. 是否禮貌 (Checkboxes)
            _buildToggleRow('是否禮貌', _isPolite, (val) => setState(() => _isPolite = val)),
            const SizedBox(height: 20),

            // 3. 評論區
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('評論', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: '輸入你的評論...',
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
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
//  8. 乘客詳細資料視窗內容
// ==========================================
class PassengerDetailsContent extends StatelessWidget {
  final String name;
  final int rating;
  
  const PassengerDetailsContent({super.key, required this.name, required this.rating});

  @override
  Widget build(BuildContext context) {
    final bool hasViolation = name == '乘客 1';
    final String violationText = hasViolation ? '有惡意取消行程紀錄' : '無違規紀錄';
    final Color violationColor = hasViolation ? Colors.red : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$name 的詳細資料', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          
          // 1. 星等
          const SizedBox(height: 15),
          const Text('星等：', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: List.generate(5, (index) => Icon(
              index < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 24,
            )),
          ),
          
          // 2. 違規紀錄
          const SizedBox(height: 20),
          const Text('違規紀錄：', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            violationText,
            style: TextStyle(color: violationColor, fontSize: 16),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}