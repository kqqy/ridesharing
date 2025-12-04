import 'package:flutter/material.dart';
import 'home_page.dart'; // 引入首頁

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true; // true=登入模式, false=註冊模式

  // 基本資料輸入框
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // 處理按鈕點擊
  Future<void> _handleSubmit() async {
    if (isLogin) {
      // --- 情況 A: 登入模式 ---
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // --- 情況 B: 註冊模式 ---
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PassengerSettingsPage()),
      );

      if (result == true) {
        if (!mounted) return;
        setState(() {
          isLogin = true;
          _passwordController.clear();
        });
      }
    }
  }

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

              // 基本資料欄位
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '電子郵件',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              if (!isLogin) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: '手機號碼',
                    prefixIcon: Icon(Icons.phone_android),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _passwordController,
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
                  onPressed: _handleSubmit,
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
                    onPressed: () {
                      setState(() {
                        isLogin = !isLogin;
                      });
                    },
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
//  👇 乘客設定頁面 (已更新：註冊成功視窗不顯示興趣)
// ==========================================

class PassengerSettingsPage extends StatefulWidget {
  const PassengerSettingsPage({super.key});

  @override
  State<PassengerSettingsPage> createState() => _PassengerSettingsPageState();
}

class _PassengerSettingsPageState extends State<PassengerSettingsPage> {
  // 1. 個性選項
  final List<String> personalityList = ['社恐', 'I人', '普通', 'E人', '社牛'];
  String? selectedPersonality;

  // 2. 興趣選項
  final List<String> interestOptions = [
    '運動', '聽音樂', '手工藝', '攝影', '繪畫', '寫程式'
  ];
  List<String> selectedInterests = [];

  // 3. 氣氛選項
  final List<String> vibeOptions = ['安靜', '普通', '愛聊天'];
  String selectedVibe = '普通';

  void _handleConfirm() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('註冊成功'),
        // 👇 修改這裡：只顯示簡單的成功訊息，不顯示興趣
        content: const Text('您的資料已設定完成！\n請使用剛剛的帳號登入。'), 
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 關掉對話框
              Navigator.pop(context, true); // 回傳 true
            },
            child: const Text('回到登入頁'),
          ),
        ],
      ),
    );
  }

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
              onChanged: (val) => setState(() => selectedPersonality = val),
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
                    if (selected) setState(() => selectedVibe = vibe);
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
                onPressed: _handleConfirm,
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