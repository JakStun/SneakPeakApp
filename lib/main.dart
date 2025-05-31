import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/local_settings_service.dart';
import 'package:flutter_animated_splash/flutter_animated_splash.dart';


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
      home: AnimatedSplash(
        type: Transition.fade,
        curve: Curves.fastEaseInToSlowEaseOut,
        backgroundColor: Colors.black,
        durationInSeconds: 3,
        navigator: HomeScreen(),
        child: Image.asset('assets/logo_foreground.png')),
        

      debugShowCheckedModeBanner: false,
    );
  }
}