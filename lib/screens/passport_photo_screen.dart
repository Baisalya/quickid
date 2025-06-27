
// lib/screens/passport_photo_screen.dart
import 'package:flutter/material.dart';

class PassportPhotoScreen extends StatefulWidget {
  @override
  _PassportPhotoScreenState createState() => _PassportPhotoScreenState();
}

class _PassportPhotoScreenState extends State<PassportPhotoScreen> {
  String selectedBackground = "white";
  String selectedDress = "Gents";
  List<int> selectedCopies = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Passport Photo Maker")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Placeholder(fallbackHeight: 200),
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
              items: ["Gents", "Ladies", "Kids"].map((e) => DropdownMenuItem(value: e, child: Text("Formal - $e"))).toList(),
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
              onPressed: () => Navigator.pushNamed(context, '/export'),
              child: Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}