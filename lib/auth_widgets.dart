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
