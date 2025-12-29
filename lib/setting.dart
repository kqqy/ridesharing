import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'setting_widgets.dart';
import 'violation_service.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('users')
          .select('nickname, auto_approve')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _nameController.text = data['nickname'] ?? '';
          _isAutoApprove = data['auto_approve'] ?? false;
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('姓名更新成功')),
        );
      }
    } catch (e) {
      debugPrint('Save name error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗: $e')),
        );
      }
    }
  }

  Future<void> _saveAutoApprove(bool value) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('users')
          .update({'auto_approve': value})
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? '已開啟自動審核' : '已關閉自動審核')),
        );
      }
    } catch (e) {
      debugPrint('Save auto_approve error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗: $e')),
        );
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
        _saveAutoApprove(value);
      },
      nameController: _nameController,
      onNameSubmitted: _saveName,
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

  final List<String> personalityList = ['社恐', 'I人', '普通', 'E人', '社牛'];
  final List<String> interestOptions = ['運動', '聽音樂', '手工藝', '攝影', '繪畫', '寫程式'];
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('個人偏好已更新')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Update preferences error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失敗: $e')),
        );
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

// ==========================================
//  3. 違規狀態頁面
// ==========================================

class ViolationStatusPage extends StatefulWidget {
  const ViolationStatusPage({super.key});

  @override
  State<ViolationStatusPage> createState() => _ViolationStatusPageState();
}

class _ViolationStatusPageState extends State<ViolationStatusPage> {
  final _service = ViolationService();
  final _supabase = Supabase.instance.client;

  int violationCount = 0;
  String status = "載入中...";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final result = await _service.getViolationStatus(user.id);
      if (mounted) {
        setState(() {
          violationCount = result['count'];
          status = result['status'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load violation status error: $e');
      if (mounted) {
        setState(() {
          status = "讀取失敗";
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ViolationStatusBody(
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

  @override
  void dispose() {
    _carModelController.dispose();
    _licensePlateController.dispose();
    super.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('車輛資訊已更新')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Update car info error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失敗: $e')),
        );
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