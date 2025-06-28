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
  String selectedBackground = "";
  String selectedDress = "Original";
  int selectedCopy = 4;

  Uint8List? _originalImageBytes;
  Uint8List? _processedImageBytes;
  final ImagePicker _picker = ImagePicker();
  bool isProcessing = false;

  // Dress position and scale
  Offset _dressOffset = Offset(0, 0);
  double _dressScale = 1.0;
  Offset _initialFocalPoint = Offset.zero;
  Offset _initialDressOffset = Offset.zero;
  double _initialDressScale = 1.0;

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
        options: FaceDetectorOptions(enableContours: false, enableLandmarks: false),
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
      final withBg = img.Image(width: decodedImage.width, height: decodedImage.height);
      img.fill(withBg, color: bgColor);

      for (int y = 0; y < decodedImage.height; y++) {
        for (int x = 0; x < decodedImage.width; x++) {
          final pixel = decodedImage.getPixel(x, y);
          if (pixel.a > 0) withBg.setPixel(x, y, pixel);
        }
      }

      final topPadding = (decodedImage.height * 0.15).toInt();
      final paddedImage = img.Image(
        width: withBg.width,
        height: withBg.height + topPadding,
      );
      img.fill(paddedImage, color: bgColor);

      for (int y = 0; y < withBg.height; y++) {
        for (int x = 0; x < withBg.width; x++) {
          paddedImage.setPixel(x, y + topPadding, withBg.getPixel(x, y));
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
        _dressOffset = Offset(0, 0); // Reset dress position
        _dressScale = 1.0;
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Passport Photo Maker"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: isProcessing
                    ? Center(child: CircularProgressIndicator(color: Colors.white))
                    : imageToShow != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.memory(imageToShow!, fit: BoxFit.contain),
                      ),
                      if (_processedImageBytes != null && selectedDress != "Original")
                        Positioned(
                          left: _dressOffset.dx,
                          top: _dressOffset.dy,
                          child: GestureDetector(
                            onScaleStart: (details) {
                              _initialFocalPoint = details.focalPoint;
                              _initialDressOffset = _dressOffset;
                              _initialDressScale = _dressScale;
                            },
                            onScaleUpdate: (details) {
                              setState(() {
                                _dressScale = (_initialDressScale * details.scale).clamp(0.5, 2.5);
                                final delta = details.focalPoint - _initialFocalPoint;
                                _dressOffset = _initialDressOffset + delta;
                              });
                            },
                            child: Transform.scale(
                              scale: _dressScale,
                              child: Image.asset(
                                _getDressAssetPath(selectedDress),
                                width: 200,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload, color: Colors.white70, size: 40),
                      SizedBox(height: 8),
                      Text("Tap to upload photo", style: TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
              ),
            ),
            if (_processedImageBytes != null && selectedDress == "Gents")
              TextButton(
                onPressed: () {
                  setState(() {
                    _dressOffset = Offset(0, 0);
                    _dressScale = 1.0;
                  });
                },
                child: Text("Reset Dress Position", style: TextStyle(color: Colors.white70)),
              ),
            SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text("Background", style: TextStyle(color: Colors.white70, fontSize: 16)),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: ["white", "blue", "grey"].map((color) {
                return ChoiceChip(
                  label: Text(color, style: TextStyle(color: Colors.white)),
                  selectedColor: Colors.blueGrey[700],
                  selected: selectedBackground == color,
                  onSelected: (_) {
                    setState(() => selectedBackground = color);
                    if (_originalImageBytes != null) _removeBackground();
                  },
                  backgroundColor: Colors.grey[800],
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text("Dress Type", style: TextStyle(color: Colors.white70, fontSize: 16)),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: DropdownButton<String>(
                dropdownColor: Colors.grey[900],
                value: selectedDress,
                underline: SizedBox(),
                iconEnabledColor: Colors.white70,
                style: TextStyle(color: Colors.white),
                isExpanded: true,
                onChanged: (val) => setState(() => selectedDress = val!),
                items: ["Original", "Gents", "Ladies", "Kids"]
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text("Formal - $e"),
                ))
                    .toList(),
              ),
            ),
            SizedBox(height: 24),

            Align(
              alignment: Alignment.centerLeft,
              child: Text("No. of Copies", style: TextStyle(color: Colors.white70, fontSize: 16)),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [4, 6, 8, 16].map((num) {
                return ChoiceChip(
                  label: Text('$num', style: TextStyle(color: Colors.white)),
                  selectedColor: Colors.deepPurple,
                  selected: selectedCopy == num,
                  onSelected: (_) => setState(() => selectedCopy = num),
                  backgroundColor: Colors.grey[800],
                );
              }).toList(),
            ),
            SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
                icon: Icon(Icons.check_circle_outline),
                label: Text("Continue"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _processedImageBytes != null ? Colors.deepPurple : Colors.grey[800],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDressAssetPath(String dressType) {
    switch (dressType) {
      case "Gents":
        return 'assets/dress/dress_gents.png';
      case "Ladies":
        return 'assets/dress/dress_ladies.png';
      case "Kids":
        return 'assets/dress/dress_kids.png';
      default:
        return ''; // No overlay
    }
  }
}
