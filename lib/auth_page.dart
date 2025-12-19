import 'package:flutter/material.dart';
import 'home_page.dart'; // 引入首頁
import 'auth_widgets.dart'; // 引入 UI 檔案
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final TextEditingController _nameController = TextEditingController(); // [新增] 姓名控制器
  final supabase = Supabase.instance.client;


  // 處理按鈕點擊
// ===== Email 正規化（非常重要）=====
String _normalizeEmail(String input) {
  return input
      .trim()
      .replaceAll('＠', '@') // 全形 @
      .replaceAll('　', '')  // 全形空白
      .replaceAll(' ', '');  // 半形空白
}

// ===== 登入 / 註冊處理 =====
Future<void> _handleSubmit() async {
  final email = _normalizeEmail(_emailController.text);
  final password = _passwordController.text.trim();
  final name = _nameController.text.trim();
  final phone = _phoneController.text.trim();

  // ===== 前端基本驗證（避免無意義請求）=====
  if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('請輸入正確的 Email')),
    );
    return;
  }

  if (password.length < 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('密碼至少需要 6 碼')),
    );
    return;
  }

  try {
    if (isLogin) {
      // =====================
      // 登入
      // =====================
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // =====================
      // 註冊
      // =====================
      if (name.isEmpty || phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請填寫姓名與手機號碼')),
        );
        return;
      }

      final res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw '註冊失敗，請確認信箱格式或稍後再試';
      }

      // ⭐ 建立 users / profiles 資料
      await supabase.from('users').insert({
        'id': user.id,
        'email': email,        // users 表有 email :contentReference[oaicite:2]{index=2}
        'phone': phone,        // users 表有 phone :contentReference[oaicite:3]{index=3}
        'nickname': name,      // users 表是 nickname :contentReference[oaicite:4]{index=4}
        'created_at': DateTime.now().toIso8601String(), // 表有 created_at :contentReference[oaicite:5]{index=5}
      });


      // 進偏好設定頁
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PassengerSettingsPage()),
      );

      if (result == true && mounted) {
        setState(() {
          isLogin = true;
          _passwordController.clear();
        });
      }
    }
  } catch (e) {
    debugPrint('Auth error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('錯誤：$e')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return AuthBody(
      isLogin: isLogin,
      emailController: _emailController,
      passwordController: _passwordController,
      phoneController: _phoneController,
      nameController: _nameController, // [新增] 傳遞給 UI
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