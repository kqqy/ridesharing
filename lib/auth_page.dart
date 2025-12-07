import 'package:flutter/material.dart';
import 'home_page.dart'; // 引入首頁
import 'auth_widgets.dart'; // 引入 UI 檔案

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
    return AuthBody(
      isLogin: isLogin,
      emailController: _emailController,
      passwordController: _passwordController,
      phoneController: _phoneController,
      onToggleMode: () {
        setState(() {
          isLogin = !isLogin;
        });
      },
      onSubmit: _handleSubmit,
    );
  }
}

// ==========================================
//  👇 乘客設定頁面 (邏輯層)
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
    return PassengerSettingsBody(
      personalityList: personalityList,
      selectedPersonality: selectedPersonality,
      onPersonalityChanged: (val) => setState(() => selectedPersonality = val),
      
      interestOptions: interestOptions,
      selectedInterests: selectedInterests,
      onInterestToggle: (interest, selected) {
        setState(() {
          if (selected) {
            selectedInterests.add(interest);
          } else {
            selectedInterests.remove(interest);
          }
        });
      },
      
      vibeOptions: vibeOptions,
      selectedVibe: selectedVibe,
      onVibeChanged: (val) => setState(() => selectedVibe = val),
      
      onConfirm: _handleConfirm,
    );
  }
}