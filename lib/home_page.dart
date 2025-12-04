import 'package:flutter/material.dart';
import 'setting.dart';
import 'driver_home.dart';    // 引入司機頁面
import 'passenger_home.dart'; // 引入乘客頁面

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isDriver = false; // false=乘客, true=司機

  @override
  Widget build(BuildContext context) {
    final Color currentColor = isDriver ? Colors.green.shade300 : Colors.blue.shade300;
    final String currentRole = isDriver ? '司機' : '乘客';

    return Scaffold(
      appBar: AppBar(
        title: Text(currentRole, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: currentColor,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10),
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  isDriver = !isDriver;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: currentColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: Text(
                isDriver ? '切換乘客' : '切換司機',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // 根據角色顯示對應的檔案
      body: isDriver 
          ? DriverHome(themeColor: currentColor) 
          : PassengerHome(themeColor: currentColor),
    );
  }
}