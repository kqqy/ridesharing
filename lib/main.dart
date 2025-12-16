import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_page.dart';
import 'active_trip_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase 初始化
  await Supabase.initialize(
    url: 'https://pzyfvhxmugtrrfaraxfi.supabase.co',           // 換成你的 Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6eWZ2aHhtdWd0cnJmYXJheGZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ5MzQzNjcsImV4cCI6MjA4MDUxMDM2N30.5AKQdRxTeS9KBYw98GOIL69MsjN509iyBQic3TyQCHs',                     // 換成你的 anon key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ridesharing',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ActiveTripPage(),
    );
  }
}

// ⚠️ 之後在任何地方要用 Supabase 時用這個：
final supabase = Supabase.instance.client;
