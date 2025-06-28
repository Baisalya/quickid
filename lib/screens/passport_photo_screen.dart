import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PassportPhotoScreen extends StatefulWidget {
  @override
  _PassportPhotoScreenState createState() => _PassportPhotoScreenState();
}

class _PassportPhotoScreenState extends State<PassportPhotoScreen> {
  String selectedBackground = "white";
  String selectedDress = "Gents";
  List<int> selectedCopies = [];
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No image selected")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
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
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.fitHeight)
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
                  selected: selectedCopies.contains(num),
                  onSelected: (_) {
                    setState(() {
                      if (selectedCopies.contains(num)) {
                        selectedCopies.remove(num);
                      } else {
                        selectedCopies.add(num);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _selectedImage != null
                  ? () {
                // Pass _selectedImage to next screen using Navigator
                Navigator.pushNamed(context, '/export', arguments: _selectedImage);
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
