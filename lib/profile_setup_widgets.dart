import 'package:flutter/material.dart';

// ==========================================
//  UI 元件：乘客設定主體 (ProfileSetupBody)
//  註：保持與原始 PassengerSettingsBody 相同的配置與配置
// ==========================================
class ProfileSetupBody extends StatelessWidget {
  final List<String> personalityList;
  final String? selectedPersonality;
  final ValueChanged<String?> onPersonalityChanged;

  final List<String> interestOptions;
  final List<String> selectedInterests;
  final Function(String, bool) onInterestToggle;

  final List<String> vibeOptions;
  final String selectedVibe;
  final ValueChanged<String> onVibeChanged;

  final VoidCallback onConfirm;

  const ProfileSetupBody({
    super.key,
    required this.personalityList,
    required this.selectedPersonality,
    required this.onPersonalityChanged,
    required this.interestOptions,
    required this.selectedInterests,
    required this.onInterestToggle,
    required this.vibeOptions,
    required this.selectedVibe,
    required this.onVibeChanged,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('乘客設定'),
        backgroundColor: Colors.blue[300],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. 個性 ---
            const Text('您的個性', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedPersonality,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '請選擇您的個性',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              ),
              items: personalityList.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: onPersonalityChanged,
            ),
            const SizedBox(height: 24),

            // --- 2. 興趣 / 專長 (多選) ---
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

            // --- 3. 共乘喜好 ---
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
            const SizedBox(height: 30),

            // 提示字
            Center(
              child: Text('之後可以從設定更改', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ),
            const SizedBox(height: 10),

            // 確認按鈕
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('確認', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}