import 'package:flutter/material.dart';
import 'auth_page.dart'; 
import 'setting_widgets.dart'; // [修正] 確保引入這個檔案

// ==========================================
//  1. 設定列表頁面 (主入口)
// ==========================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      onLogout: () {
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
  final List<String> personalityList = ['社恐', 'I人', '普通', 'E人', '社牛'];
  final List<String> interestOptions = ['運動', '聽音樂', '手工藝', '攝影', '繪畫', '寫程式'];
  final List<String> vibeOptions = ['安靜', '普通', '愛聊天'];

  String? selectedPersonality;
  List<String> selectedInterests = [];
  String selectedVibe = '普通';

  @override
  void initState() {
    super.initState();
    selectedPersonality = 'I人';
    selectedInterests = ['寫程式', '聽音樂'];
    selectedVibe = '安靜';
  }

  // [修正] 加入 mounted 檢查
  void _handleSave() async {
    // 模擬存檔延遲
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 檢查頁面是否還在，若不在則停止執行，避免報錯
    if (!mounted) return; 
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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

class ViolationStatusPage extends StatelessWidget {
  const ViolationStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    const int violationCount = 0;
    const String status = "正常"; 

    // 因為 ViolationStatusBody 是 StatelessWidget 且參數固定，這裡可以使用 const
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
  final TextEditingController _carModelController = TextEditingController(); 
  final TextEditingController _licensePlateController = TextEditingController();

  // [修正] 加入 mounted 檢查
  void _handleSave() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return EditCarInfoBody(
      carModelController: _carModelController,
      licensePlateController: _licensePlateController,
      onSave: _handleSave,
    );
  }
}