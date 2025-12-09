import 'package:flutter/material.dart';

// ==========================================
//  1. UI 元件：登入/註冊主體 (AuthBody)
// ==========================================
class AuthBody extends StatelessWidget {
  final bool isLogin;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController phoneController;
  final TextEditingController nameController; // [新增] 姓名控制器
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;

  const AuthBody({
    super.key,
    required this.isLogin,
    required this.emailController,
    required this.passwordController,
    required this.phoneController,
    required this.nameController, // [新增]
    required this.onToggleMode,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.directions_car_filled, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                isLogin ? '歡迎回來' : '建立帳戶',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                isLogin ? '請輸入帳號密碼以繼續' : '第一步：填寫基本資料',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),

              // 電子郵件 (登入/註冊皆有)
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '電子郵件',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // [修改] 註冊模式專用欄位 (姓名 + 手機)
              if (!isLogin) ...[
                // [新增] 姓名欄位
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '姓名',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 手機號碼欄位
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '手機號碼',
                    prefixIcon: Icon(Icons.phone_android),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 密碼 (登入/註冊皆有)
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密碼',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // 主要按鈕
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isLogin ? '登入' : '設定偏好',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 切換模式文字
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLogin ? '還沒有帳號嗎？' : '已經有帳號了？'),
                  TextButton(
                    onPressed: onToggleMode,
                    child: Text(isLogin ? '立即註冊' : '直接登入'),
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
//  2. UI 元件：乘客設定主體 (PassengerSettingsBody)
// ==========================================
class PassengerSettingsBody extends StatelessWidget {
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

  const PassengerSettingsBody({
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

            // --- 2. 興趣專長 (多選) ---
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