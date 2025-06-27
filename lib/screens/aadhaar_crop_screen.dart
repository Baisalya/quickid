import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'export_screen.dart';

class AadhaarCropScreen extends StatefulWidget {
  @override
  _AadhaarCropScreenState createState() => _AadhaarCropScreenState();
}

class _AadhaarCropScreenState extends State<AadhaarCropScreen> {
  File? _image;
  bool _whiteBackground = true;
  String _format = "JPG";
  String _resolution = "1080p";

  Future<void> _pickAndAutoCropImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      File cropped = await _autoCropAadhaarCard(File(picked.path));
      setState(() {
        _image = cropped;
      });
    }
  }

  Future<File> _autoCropAadhaarCard(File originalFile) async {
    final bytes = await originalFile.readAsBytes();
    img.Image originalImage = img.decodeImage(bytes)!;

    // Define a fixed central cropping box
    int cropX = (originalImage.width * 0.1).toInt();
    int cropY = (originalImage.height * 0.25).toInt();
    int cropWidth = (originalImage.width * 0.8).toInt();
    int cropHeight = (originalImage.height * 0.5).toInt();

    img.Image cropped = img.copyCrop(
      originalImage,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    // Optionally fill white background
/*
    if (_whiteBackground) {
      img.Image whiteBg = img.Image(width: cropped.width, height: cropped.height);
      whiteBg.fill(0xFFFFFFFF); // White background
      img.copyInto(whiteBg, cropped);
      cropped = whiteBg;
    }
*/

    final dir = await getTemporaryDirectory();
    final ext = _format.toLowerCase();
    final fileName = 'aadhaar_cropped.$ext';
    final file = File('${dir.path}/$fileName');

    if (_format == "PNG") {
      await file.writeAsBytes(img.encodePng(cropped));
    } else {
      await file.writeAsBytes(img.encodeJpg(cropped));
    }

    return file;
  }

  void _export() {
    // You can pass _image, _format, _resolution to ExportScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ExportScreen(imageFile: _image)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Aadhaar Crop")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAndAutoCropImage,
              child: _image != null
                  ? Image.file(_image!, height: 200)
                  : Container(
                height: 200,
                color: Colors.grey[300],
                child: Center(child: Text("Tap to upload Aadhaar image")),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text("White Background"),
                Spacer(),
                Switch(
                  value: _whiteBackground,
                  onChanged: (val) => setState(() => _whiteBackground = val),
                ),
              ],
            ),
            DropdownButton<String>(
              value: _format,
              onChanged: (val) => setState(() => _format = val!),
              items: ["JPG", "PNG"].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
            ),
            DropdownButton<String>(
              value: _resolution,
              onChanged: (val) => setState(() => _resolution = val!),
              items: ["1080p", "2K", "4K"].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _image != null ? _export : null,
              child: Text("Export"),
            ),
          ],
        ),
      ),
    );
  }
}
