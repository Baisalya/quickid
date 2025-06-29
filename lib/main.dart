// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/aadhaar_crop_screen.dart';
import 'screens/passport_photo_screen.dart';
import 'screens/export_screen.dart';

void main() => runApp(const PhotoApp());

class PhotoApp extends StatelessWidget {
  const PhotoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aadhaar & Passport Photo Maker',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/aadhaar_crop': (context) => const AadhaarCropScreen(),
        '/passport_photo': (context) => const PassportPhotoScreen(),
        '/export': (context) => const ExportScreen(),
      },
    );
  }
}





