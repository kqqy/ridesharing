import 'package:flutter/material.dart';

// ==========================================
//  UI 元件：創建行程的表單介面
// ==========================================
class PassengerCreateTripForm extends StatelessWidget {
  final TextEditingController originController;
  final TextEditingController destinationController;
  final TextEditingController timeController;
  final TextEditingController seatsController;
  final TextEditingController noteController;
  
  final VoidCallback onTimeTap;   
  final VoidCallback onSubmit;    

  const PassengerCreateTripForm({
    super.key,
    required this.originController,
    required this.destinationController,
    required this.timeController,
    required this.seatsController,
    required this.noteController,
    required this.onTimeTap,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('建立新行程', style: TextStyle(fontWeight: FontWeight.bold)),
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
            _buildSectionTitle('行程資訊'),
            const SizedBox(height: 15),
            
            // 1. 出發地
            _buildTextField(
              controller: originController,
              label: '出發地',
              icon: Icons.my_location,
            ),
            const SizedBox(height: 15),

            // 2. 目的地
            _buildTextField(
              controller: destinationController,
              label: '目的地',
              icon: Icons.flag,
            ),
            const SizedBox(height: 15),

            // 3. 出發時間
            _buildTextField(
              controller: timeController,
              label: '出發時間',
              icon: Icons.access_time,
              readOnly: true,
              onTap: onTimeTap,
            ),
            const SizedBox(height: 15),

            // 4. 可乘座位數 (固定不可改)
            _buildTextField(
              controller: seatsController,
              label: '可乘座位數 (固定)',
              icon: Icons.event_seat,
              readOnly: true, // [修改] 設定為唯讀
              textColor: Colors.grey, // [修改] 讓文字變灰顯示為不可編輯狀態
            ),
            const SizedBox(height: 25),

            // 5. 備註
            Row(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 12.0, right: 16.0),
                  child: Text(
                    '備註',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black87
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: noteController,
                    maxLines: 3, 
                    decoration: InputDecoration(
                      hintText: '請輸入備註事項...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 6. 創建按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Text('創建行程', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
    );
  }

  // 小工具：統一的輸入框樣式
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    Color? textColor, // [新增] 可自訂文字顏色
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(color: textColor ?? Colors.black), // 套用顏色
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        isDense: true,
        // 如果唯讀，背景稍微變灰一點點
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
      ),
    );
  }
}