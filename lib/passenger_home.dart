import 'package:flutter/material.dart';

class PassengerHome extends StatelessWidget {
  final Color themeColor;

  const PassengerHome({super.key, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_rounded, size: 80, color: themeColor),
            ),
            const SizedBox(height: 20),
            const Text(
              '目前還沒有行程',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}