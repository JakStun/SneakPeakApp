import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/local_settings_service.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await LocalSettingsService.initialize();
  print('User Key: ${LocalSettingsService.userKey}');
  runApp(const MyApp());
  }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera App test 1',
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}