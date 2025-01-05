import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import './screens/login_screen.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // await FirebaseAppCheck.instance.activate(
    //   androidProvider: AndroidProvider.debug,
    //   appleProvider: AppleProvider.debug,
    // );
  } catch (e) {
    print('Firebase initialization error: $e');
  }   

  await _requestPermissions();

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  try {
    await Permission.sms.request();
    await Permission.phone.request();
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  } catch (e) {
    print('Error requesting permissions: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
