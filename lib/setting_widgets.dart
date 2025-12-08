import 'package:flutter/material.dart';

// ==========================================
//  1. UI 元件：設定列表主體 (SettingsBody)
// ==========================================
class SettingsBody extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onEditPreferences;
  final VoidCallback onViolationStatus;
  final VoidCallback onEditCarInfo;
  
  // [新增] 自動審核相關參數
  final bool isAutoApprove;
  final ValueChanged<bool> onAutoApproveChanged;

  const SettingsBody({
    super.key,
    required this.onLogout,
    required this.onEditPreferences,
    required this.onViolationStatus,
    required this.onEditCarInfo,
    required this.isAutoApprove, // [新增]
    required this.onAutoApproveChanged, // [新增]
  });

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
            onTap: onLogout,
          ),
          const Divider(thickness: 5, color: Color(0xFFF5F5F5)),

          // 乘客設定區塊
          _buildSectionTitle('乘客設定'),
          
          // [新增] 自動審核成員開關
          SwitchListTile(
            secondary: Icon(Icons.person_add_alt, color: Colors.blue[300]),
            title: const Text('審核要求'),
            subtitle: const Text('關閉後，系統將自動同意加入請求'),
            value: isAutoApprove,
            onChanged: onAutoApproveChanged,
            activeColor: Colors.blue,
          ),

          // 編輯偏好按鈕
          ListTile(
            leading: Icon(Icons.favorite_border, color: Colors.blue[300]),
            title: const Text('編輯偏好'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: onEditPreferences,
          ),
          
          // 違規次數與停權狀態按鈕
          ListTile(
            leading: Icon(Icons.warning_amber_rounded, color: Colors.blue[300]),
            title: const Text('違規次數與停權狀態'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: onViolationStatus,
          ),

          const Divider(thickness: 5, color: Color(0xFFF5F5F5)),

          // 司機設定區塊
          _buildSectionTitle('司機設定'),

          // 編輯車子資訊按鈕
          ListTile(
            leading: Icon(Icons.directions_car_outlined, color: Colors.blue[300]),
            title: const Text('編輯車子資訊'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: onEditCarInfo,
          ),
        ],
      ),
    );
  }

  // 小標題工具
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
}

// ==========================================
//  2. UI 元件：編輯偏好主體 (EditPreferencesBody)
// ==========================================
class EditPreferencesBody extends StatelessWidget {
  final List<String> personalityList;
  final List<String> interestOptions;
  final List<String> vibeOptions;
  
  final String? selectedPersonality;
  final List<String> selectedInterests;
  final String selectedVibe;

  final ValueChanged<String?> onPersonalityChanged;
  final Function(String, bool) onInterestToggle;
  final ValueChanged<String> onVibeChanged;
  final VoidCallback onSave;

  const EditPreferencesBody({
    super.key,
    required this.personalityList,
    required this.interestOptions,
    required this.vibeOptions,
    required this.selectedPersonality,
    required this.selectedInterests,
    required this.selectedVibe,
    required this.onPersonalityChanged,
    required this.onInterestToggle,
    required this.onVibeChanged,
    required this.onSave,
  });

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
              onChanged: onPersonalityChanged,
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
                  onSelected: (bool selected) => onInterestToggle(interest, selected),
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
                    if (selected) onVibeChanged(vibe);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onSave,
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
//  3. UI 元件：違規狀態主體 (ViolationStatusBody)
// ==========================================
class ViolationStatusBody extends StatelessWidget {
  final int violationCount;
  final String status;

  const ViolationStatusBody({
    super.key,
    required this.violationCount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
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
//  4. UI 元件：編輯車子資訊主體 (EditCarInfoBody)
// ==========================================
class EditCarInfoBody extends StatelessWidget {
  final TextEditingController carModelController;
  final TextEditingController licensePlateController;
  final VoidCallback onSave;

  const EditCarInfoBody({
    super.key,
    required this.carModelController,
    required this.licensePlateController,
    required this.onSave,
  });

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
              controller: carModelController, 
              decoration: const InputDecoration(
                labelText: '車種',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
              ),
            ),
            const SizedBox(height: 20),

            // 車牌
            TextField(
              controller: licensePlateController,
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
                onPressed: onSave,
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