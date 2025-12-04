import 'package:flutter/material.dart';
import 'auth_page.dart'; // 為了讓登出按鈕能跳回登入頁

// ==========================================
//  1. 設定列表頁面 (主入口)
// ==========================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: ListView(
        children: [
          // 登出按鈕
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('登出帳號', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthPage()),
                (route) => false,
              );
            },
          ),
          const Divider(thickness: 5, color: Color(0xFFF5F5F5)),

          // 乘客設定區塊
          _buildSectionTitle('乘客設定'),
          
          // 編輯偏好按鈕
          ListTile(
            leading: Icon(Icons.favorite_border, color: Colors.blue[300]),
            title: const Text('編輯偏好'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditPreferencesPage()),
              );
            },
          ),
          
          // 違規次數與停權狀態按鈕
          ListTile(
            leading: Icon(Icons.warning_amber_rounded, color: Colors.blue[300]),
            title: const Text('違規次數與停權狀態'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ViolationStatusPage()),
              );
            },
          ),

          const Divider(thickness: 5, color: Color(0xFFF5F5F5)),

          // 司機設定區塊
          _buildSectionTitle('司機設定'),

          // 編輯車子資訊按鈕
          ListTile(
            leading: Icon(Icons.directions_car_outlined, color: Colors.blue[300]),
            title: const Text('編輯車子資訊'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditCarInfoPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // 小標題工具 (這個還有用到，所以保留)
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  // ⚠️ 我把原本在這裡的 _buildSettingsItem 刪掉了，因為沒用到了
}

// ==========================================
//  2. 編輯偏好頁面
// ==========================================

class EditPreferencesPage extends StatefulWidget {
  const EditPreferencesPage({super.key});

  @override
  State<EditPreferencesPage> createState() => _EditPreferencesPageState();
}

class _EditPreferencesPageState extends State<EditPreferencesPage> {
  final List<String> personalityList = ['社恐', 'I人', '普通', 'E人', '社牛'];
  final List<String> interestOptions = ['運動', '聽音樂', '手工藝', '攝影', '繪畫', '寫程式'];
  final List<String> vibeOptions = ['安靜', '普通', '愛聊天'];

  String? selectedPersonality;
  List<String> selectedInterests = [];
  String selectedVibe = '普通';

  @override
  void initState() {
    super.initState();
    selectedPersonality = 'I人';
    selectedInterests = ['寫程式', '聽音樂'];
    selectedVibe = '安靜';
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('偏好設定已更新！'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯偏好'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('您的個性', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedPersonality,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              ),
              items: personalityList.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (val) => setState(() => selectedPersonality = val),
            ),
            const SizedBox(height: 24),

            const Text('興趣 / 專長 (可多選)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: interestOptions.map((interest) {
                final bool isSelected = selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        selectedInterests.add(interest);
                      } else {
                        selectedInterests.remove(interest);
                      }
                    });
                  },
                  selectedColor: Colors.blue[100],
                  checkmarkColor: Colors.blue[900],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            const Text('共乘喜好', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('車內氣氛', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10.0,
              children: vibeOptions.map((vibe) {
                final isSelected = selectedVibe == vibe;
                return ChoiceChip(
                  label: Text(vibe),
                  selected: isSelected,
                  selectedColor: Colors.blue[100],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue[900] : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => selectedVibe = vibe);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('儲存修改', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
//  3. 違規狀態頁面
// ==========================================

class ViolationStatusPage extends StatelessWidget {
  const ViolationStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final int violationCount = 0;
    final String status = "正常"; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('違規與停權狀態'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.grey, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildStatusRow('違規次數', '$violationCount 次', Colors.red),
              ),
            ),
            const SizedBox(height: 16), 
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.grey, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildStatusRow('停權狀態', status, Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }
}

// ==========================================
//  4. 編輯車子資訊頁面
// ==========================================

class EditCarInfoPage extends StatefulWidget {
  const EditCarInfoPage({super.key});

  @override
  State<EditCarInfoPage> createState() => _EditCarInfoPageState();
}

class _EditCarInfoPageState extends State<EditCarInfoPage> {
  final TextEditingController _carModelController = TextEditingController(); 
  final TextEditingController _licensePlateController = TextEditingController();

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('車子資訊已更新！'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('編輯車子資訊'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 車種
            TextField(
              controller: _carModelController, 
              decoration: const InputDecoration(
                labelText: '車種',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
              ),
            ),
            const SizedBox(height: 20),

            // 車牌
            TextField(
              controller: _licensePlateController,
              decoration: const InputDecoration(
                labelText: '車牌',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 40),

            // 儲存按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('儲存修改', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}