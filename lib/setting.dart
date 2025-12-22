import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart'; 
import 'setting_widgets.dart'; // 引入 UI

// ==========================================
//  1. 設定列表頁面 (主入口)
// ==========================================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final supabase = Supabase.instance.client;
  bool _isAutoApprove = false; 
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('users')
          .select('nickname')
          .eq('id', user.id)
          .single();
      
      if (mounted) {
        setState(() {
          _nameController.text = data['nickname'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Load profile error: $e');
    }
  }

  Future<void> _saveName(String newName) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('users')
          .update({'nickname': newName.trim()})
          .eq('id', user.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('姓名更新成功')));
      }
    } catch (e) {
      debugPrint('Save name error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('儲存失敗: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      isAutoApprove: _isAutoApprove,
      onAutoApproveChanged: (value) {
        setState(() {
          _isAutoApprove = value;
        });
      },
      nameController: _nameController,
      onNameSubmitted: _saveName, // 綁定 onSubmitted 事件

      onLogout: () async {
        await supabase.auth.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
          (route) => false,
        );
      },
      onEditPreferences: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditPreferencesPage()),
        );
      },
      onViolationStatus: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ViolationStatusPage()),
        );
      },
      onEditCarInfo: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditCarInfoPage()),
        );
      },
    );
  }
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
  final supabase = Supabase.instance.client;

  // 1. 個性選項
  final List<String> personalityList = ['社恐', 'I人', '普通', 'E人', '社牛'];
  // 2. 興趣選項
  final List<String> interestOptions = ['運動', '聽音樂', '手工藝', '攝影', '繪畫', '寫程式'];
  // 3. 氣氛選項
  final List<String> vibeOptions = ['安靜', '普通', '愛聊天'];

  String? selectedPersonality;
  List<String> selectedInterests = [];
  String selectedVibe = '普通';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('users')
          .select('mbti, interests, chat_preference')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          selectedPersonality = data['mbti'];
          final interestsStr = data['interests'] as String?;
          if (interestsStr != null && interestsStr.isNotEmpty) {
            selectedInterests = interestsStr.split(',');
          }
          selectedVibe = data['chat_preference'] ?? '普通';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load preferences error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('users').update({
        'mbti': selectedPersonality,
        'interests': selectedInterests.join(','),
        'chat_preference': selectedVibe,
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('個人偏好已更新')));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Update preferences error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失敗: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return EditPreferencesBody(
      personalityList: personalityList,
      interestOptions: interestOptions,
      vibeOptions: vibeOptions,
      selectedPersonality: selectedPersonality,
      selectedInterests: selectedInterests,
      selectedVibe: selectedVibe,
      onPersonalityChanged: (val) => setState(() => selectedPersonality = val),
      onInterestToggle: (interest, selected) {
        setState(() {
          if (selected) {
            selectedInterests.add(interest);
          } else {
            selectedInterests.remove(interest);
          }
        });
      },
      onVibeChanged: (val) => setState(() => selectedVibe = val),
      onSave: _handleSave,
    );
  }
}

// ... (ViolationStatusPage 與 EditCarInfoPage 保持不變)

// ==========================================
//  3. 違規狀態頁面
// ==========================================

class ViolationStatusPage extends StatelessWidget {
  const ViolationStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    const int violationCount = 0;
    const String status = "正常"; 

    return const ViolationStatusBody(
      violationCount: violationCount, 
      status: status
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
  final supabase = Supabase.instance.client;
  final TextEditingController _carModelController = TextEditingController(); 
  final TextEditingController _licensePlateController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCarInfo();
  }

  Future<void> _loadCarInfo() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('driver_profiles')
          .select('car_type, license_plate')
          .eq('user_id', user.id)
          .maybeSingle();

      if (mounted) {
        if (data != null) {
          _carModelController.text = data['car_type'] ?? '';
          _licensePlateController.text = data['license_plate'] ?? '';
        }
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Load car info error: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('driver_profiles').upsert({
        'user_id': user.id,
        'car_type': _carModelController.text.trim(),
        'license_plate': _licensePlateController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('車輛資訊已更新')));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Update car info error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失敗: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return EditCarInfoBody(
      carModelController: _carModelController,
      licensePlateController: _licensePlateController,
      onSave: _handleSave,
    );
  }
}
