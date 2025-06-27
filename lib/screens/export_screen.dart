import 'dart:io';
import 'package:flutter/material.dart';

class ExportScreen extends StatelessWidget {
  final File? imageFile;

  ExportScreen({this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Preview & Export")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            imageFile != null
                ? Image.file(imageFile!, height: 200)
                : Placeholder(fallbackHeight: 200),
            SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: ["JPG", "PNG", "PDF"].map((f) => ElevatedButton(onPressed: () {}, child: Text(f))).toList(),
            ),
            Spacer(),
            ElevatedButton(onPressed: () {}, child: Text("Continue")),
          ],
        ),
      ),
    );
  }
}
