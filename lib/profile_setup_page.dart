import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_setup_widgets.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final supabase = Supabase.instance.client;

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

  bool isLoading = false;

  Future<void> _handleConfirm() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('找不到使用者，請重新登入')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 根據原始 UI 配置，將「興趣 / 專長」存在 interests 欄位
      await supabase.from('users').update({
        'mbti': selectedPersonality,
        'interests': selectedInterests.join(','),
        'chat_preference': selectedVibe,
      }).eq('id', user.id);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('註冊成功'),
          content: const Text('您的資料已設定完成！\n請使用剛剛的帳號登入。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 關掉 Dialog
                Navigator.pop(context, true); // 回到 AuthPage
              },
              child: const Text('回到登入頁'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Update profile error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('儲存失敗：$e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ProfileSetupBody(
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