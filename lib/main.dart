import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
// import 'services/notification_service.dart';
// import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // NotificationHelper.init();
  // await Permission.notification.isDenied.then((value) async {
  //   if (value) {
  //     await Permission.notification.request();
  //   }
  // });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: OnboardingScreenManager(),
    );
  }
}
