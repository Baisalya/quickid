import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class PassportPhotoScreen extends StatefulWidget {
  @override
  _PassportPhotoScreenState createState() => _PassportPhotoScreenState();
}

class _PassportPhotoScreenState extends State<PassportPhotoScreen> {
  String selectedBackground = "white";
  String selectedDress = "Gents";
  int selectedCopy = 4;

  Uint8List? _processedImageBytes; // <-- used instead of File
  final ImagePicker _picker = ImagePicker();
  bool isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        _showMessage("No image selected");
        return;
      }

      setState(() {
        isProcessing = true;
      });

      final File imageFile = File(image.path);
      final inputImage = InputImage.fromFile(imageFile);

      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _showMessage("No face detected");
        setState(() => isProcessing = false);
        return;
      }

      final originalBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(originalBytes);

      if (decodedImage == null) {
        _showMessage("Failed to process image");
        setState(() => isProcessing = false);
        return;
      }

      // Resize to cover passport size
      const int targetWidth = 413;
      const int targetHeight = 531;
      final resized = img.copyResize(
        decodedImage,
        width: decodedImage.width > decodedImage.height
            ? (decodedImage.width * targetHeight / decodedImage.height).toInt()
            : targetWidth,
        height: decodedImage.height > decodedImage.width
            ? (decodedImage.height * targetWidth / decodedImage.width).toInt()
            : targetHeight,
      );

      // Crop center to 413x531
      final cropped = img.copyCrop(
        resized,
        x: (resized.width - targetWidth) ~/ 2,
        y: (resized.height - targetHeight) ~/ 2,
        width: targetWidth,
        height: targetHeight,
      );

      final jpgBytes = img.encodeJpg(cropped);

      setState(() {
        _processedImageBytes = Uint8List.fromList(jpgBytes);
        isProcessing = false;
      });
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
      setState(() => isProcessing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("Take a photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text("Choose from gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Passport Photo Maker")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  color: Colors.grey[200],
                ),
                child: isProcessing
                    ? Center(child: CircularProgressIndicator())
                    : _processedImageBytes != null
                    ? Image.memory(_processedImageBytes!, fit: BoxFit.fitHeight)
                    : Center(child: Text("Tap to upload photo")),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ["white", "blue", "grey"].map((color) {
                return ChoiceChip(
                  label: Text(color),
                  selected: selectedBackground == color,
                  onSelected: (_) => setState(() => selectedBackground = color),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              value: selectedDress,
              onChanged: (val) => setState(() => selectedDress = val!),
              items: ["Gents", "Ladies", "Kids"]
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text("Formal - $e"),
              ))
                  .toList(),
            ),
            SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: [4, 6, 8, 16].map((num) {
                return ChoiceChip(
                  label: Text('$num'),
                  selected: selectedCopy == num,
                  onSelected: (_) => setState(() => selectedCopy = num),
                );
              }).toList(),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _processedImageBytes != null
                  ? () {
                Navigator.pushNamed(
                  context,
                  '/export',
                  arguments: {
                    'imageBytes': _processedImageBytes,
                    'background': selectedBackground,
                    'dress': selectedDress,
                    'copies': selectedCopy,
                  },
                );
              }
                  : null,
              child: Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
