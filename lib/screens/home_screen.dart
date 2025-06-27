
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Aadhaar Crop +\nPassport Photo Maker",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/aadhaar_crop'),
              child: Text("Aadhaar Crop"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/passport_photo'),
              child: Text("Passport Photo Maker"),
            ),
          ],
        ),
      ),
    );
  }
}