import 'dart:io';
import 'dart:typed_data';

import 'package:background_remover/background_remover.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';

class PassportPhotoScreen extends StatefulWidget {
  @override
  _PassportPhotoScreenState createState() => _PassportPhotoScreenState();
}

class _PassportPhotoScreenState extends State<PassportPhotoScreen> {
  String selectedBackground = "white";
  String selectedDress = "Gents";
  int selectedCopy = 4;
  Rect? _faceBoundingBox;

  Uint8List? _originalImageBytes;
  Uint8List? _processedImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) {
        _showMessage("No image selected");
        return;
      }

      final File imageFile = File(image.path);
      final inputImage = InputImage.fromFile(imageFile);

      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        _showMessage("No face detected");
        return;
      }

      final originalBytes = await imageFile.readAsBytes();
      setState(() {
        _originalImageBytes = originalBytes;
        _processedImageBytes = null;
      });

      // Automatically remove background after picking
      await _removeBackground();

    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    }
  }

  Future<void> _removeBackground() async {
    if (_originalImageBytes == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final removedBgBytes = await removeBackground(imageBytes: _originalImageBytes!);
      final decodedImage = img.decodeImage(removedBgBytes);
      if (decodedImage == null) {
        _showMessage("Failed to process image");
        setState(() => isProcessing = false);
        return;
      }

      final bgColor = _getSelectedColor();

      final withWhiteBg = img.Image(
        width: decodedImage.width,
        height: decodedImage.height,
      );
      img.fill(withWhiteBg, color: bgColor);

      for (int y = 0; y < decodedImage.height; y++) {
        for (int x = 0; x < decodedImage.width; x++) {
          final pixel = decodedImage.getPixel(x, y);
          if (pixel.a > 0) {
            withWhiteBg.setPixel(x, y, pixel);
          }
        }
      }

      final topPadding = (decodedImage.height * 0.15).toInt();
      final paddedImage = img.Image(
        width: withWhiteBg.width,
        height: withWhiteBg.height + topPadding,
      );
      img.fill(paddedImage, color: bgColor);

      for (int y = 0; y < withWhiteBg.height; y++) {
        for (int x = 0; x < withWhiteBg.width; x++) {
          final pixel = withWhiteBg.getPixel(x, y);
          paddedImage.setPixel(x, y + topPadding, pixel);
        }
      }

      const targetWidth = 413;
      const targetHeight = 531;

      final resized = img.copyResize(
        paddedImage,
        width: paddedImage.width > paddedImage.height
            ? (paddedImage.width * targetHeight / paddedImage.height).toInt()
            : targetWidth,
        height: paddedImage.height > paddedImage.width
            ? (paddedImage.height * targetWidth / paddedImage.width).toInt()
            : targetHeight,
        interpolation: img.Interpolation.cubic,
      );

      final cropped = img.copyCrop(
        resized,
        x: (resized.width - targetWidth) ~/ 2,
        y: (resized.height - targetHeight) ~/ 2,
        width: targetWidth,
        height: targetHeight,
      );

      final jpgBytes = img.encodeJpg(cropped, quality: 100);

      setState(() {
        _processedImageBytes = Uint8List.fromList(jpgBytes);
      });
    } catch (e) {
      _showMessage("Error: ${e.toString()}");
    }

    setState(() => isProcessing = false);
  }

  img.ColorRgb8 _getSelectedColor() {
    switch (selectedBackground) {
      case 'blue':
        return img.ColorRgb8(0, 102, 204);
      case 'grey':
        return img.ColorRgb8(200, 200, 200);
      default:
        return img.ColorRgb8(255, 255, 255);
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
    final imageToShow = _processedImageBytes ?? _originalImageBytes;

    return Scaffold(
      appBar: AppBar(title: Text("Passport Photo Maker")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      color: Colors.grey[200],
                    ),
                    child: isProcessing
                        ? Center(child: CircularProgressIndicator())
                        : imageToShow != null
                        ? Image.memory(imageToShow, fit: BoxFit.fitHeight)
                        : Center(child: Text("Tap to upload photo")),
                  ),
                  if (_originalImageBytes != null && _processedImageBytes == null)
                    Positioned(
                      bottom: 8,
                      child: ElevatedButton(
                        onPressed: _removeBackground,
                        child: Text("Remove Background"),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ["white", "blue", "grey"].map((color) {
                return ChoiceChip(
                  label: Text(color),
                  selected: selectedBackground == color,
                  onSelected: (_) {
                    setState(() => selectedBackground = color);
                    if (_originalImageBytes != null) {
                      _removeBackground(); // regenerate with new background color
                    }
                  },
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
