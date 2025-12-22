import 'package:flutter/material.dart';
import 'home_page.dart'; // 引入首頁
import 'auth_widgets.dart'; // 引入 UI 檔案
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_setup_page.dart'; // [新增] 引入個人設定頁

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
        'email': email,        // users 表有 email
        'phone': phone,        // users 表有 phone
        'nickname': name,      // users 表是 nickname
        'created_at': DateTime.now().toIso8601String(), // 表有 created_at
      });


      // [修改] 進偏好設定頁 (使用新的 ProfileSetupPage)
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSetupPage()),
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
