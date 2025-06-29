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
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/aadhaar_crop':
            return MaterialPageRoute(builder: (_) => const AadhaarCropScreen());
          case '/passport_photo':
            return MaterialPageRoute(builder: (_) => const PassportPhotoScreen());
          case '/export':
            final args = settings.arguments as Map;
            return MaterialPageRoute(
              builder: (_) => ExportScreen(
                imageBytes: args['imageBytes'],
                background: args['background'],
                dress: args['dress'],
                copies: args['copies'],
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text("Unknown route")),
              ),
            );
        }
      },
    );
  }
}
