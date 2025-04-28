import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'firebase_options.dart';
import 'app/routes/app_pages.dart';
import 'app/bindings/app_bindings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'POS System',
      theme: ThemeData(primarySwatch: Colors.blue, visualDensity: VisualDensity.adaptivePlatformDensity),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      initialBinding: InitialBinding(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// InitialBinding moved to app/bindings/app_bindings.dart
