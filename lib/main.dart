import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
// import 'dart:js_util';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:utransport/splash_screen/splash_screen.dart';

import 'infoHandler/app_info.dart';

Future<void> main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarColor: Colors.transparent));
    return ChangeNotifierProvider(
        create: (context) => AppInfo(),
        child: MaterialApp(
          title: 'Transport-UDOM',
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
        ),

    );
  }
}


