
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Aadhaar Crop +\nPassport Photo Maker",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/aadhaar_crop'),
              child: const Text("Aadhaar Crop"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/passport_photo'),
              child: const Text("Passport Photo Maker"),
            ),
          ],
        ),
      ),
    );
  }
}