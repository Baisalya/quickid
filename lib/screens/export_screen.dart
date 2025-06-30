import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ExportScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String background;
  final String dress;
  final int copies;

  const ExportScreen({
    super.key,
    required this.imageBytes,
    required this.background,
    required this.dress,
    required this.copies,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String selectedClarity = "Normal";
  Uint8List? _enhancedBytes;
  bool isGeneratingPreview = false;
  bool showOriginal = false;

  final Map<String, List<int>> _clarityResolutionMap = {
    "Normal": [413, 531],
    "HD (1080p)": [1920, 1080],
    "2K": [2560, 1440],
    "4K": [3840, 2160],
  };

  @override
  void initState() {
    super.initState();
    _generateEnhancedImage();
  }

  Future<void> _generateEnhancedImage() async {
    setState(() => isGeneratingPreview = true);
    final clarityRes = _clarityResolutionMap[selectedClarity]!;
    final resized = await _resizeImage(widget.imageBytes, clarityRes);
    setState(() {
      _enhancedBytes = resized;
      isGeneratingPreview = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkBackground = Color(0xFF121212);
    const accent = Color(0xFF9B59B6);

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        title: const Text("Preview & Export", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Hold to view original", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            GestureDetector(
              onLongPressStart: (_) => setState(() => showOriginal = true),
              onLongPressEnd: (_) => setState(() => showOriginal = false),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: isGeneratingPreview
                    ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.deepPurple)))
                    : Image.memory(
                  showOriginal ? widget.imageBytes : (_enhancedBytes ?? widget.imageBytes),
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Dress / Background / Copies preview row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _iconPreview("Dress", widget.dress),
                _iconPreview("Background", widget.background),
                Column(
                  children: [
                    const Text("Copies", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        "${widget.copies}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Image Clarity",
                style: TextStyle(color: Colors.grey[300], fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: _clarityResolutionMap.keys.map((label) {
                return ChoiceChip(
                  label: Text(label, style: const TextStyle(color: Colors.white)),
                  selected: selectedClarity == label,
                  selectedColor: Colors.deepPurple,
                  backgroundColor: Colors.grey[800],
                  onSelected: (_) async {
                    setState(() => selectedClarity = label);
                    await _generateEnhancedImage();
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Export As",
                style: TextStyle(color: Colors.grey[300], fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: ["JPG", "PNG", "PDF"].map((format) {
                return ElevatedButton.icon(
                  onPressed: () => _exportImage(format),
                  icon: const Icon(Icons.download, size: 18),
                  label: Text("Export $format"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 5,
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
                label: const Text("Back", style: TextStyle(color: Colors.white70)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dress / Background icon preview widget
  Widget _iconPreview(String label, String imagePath) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white10,
          backgroundImage: File(imagePath).existsSync() ? FileImage(File(imagePath)) : null,
          child: !File(imagePath).existsSync()
              ? const Icon(Icons.broken_image, color: Colors.white54)
              : null,
        ),
      ],
    );
  }

  Future<void> _exportImage(String format) async {
    try {
      final clarityRes = _clarityResolutionMap[selectedClarity]!;
      final finalBytes = _enhancedBytes ?? await _resizeImage(widget.imageBytes, clarityRes);

      final dir = await getTemporaryDirectory();
      final ext = format.toLowerCase();
      final filePath = '${dir.path}/passport_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File(filePath)..writeAsBytesSync(finalBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Here is your $format passport photo');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Exported passport photo as $format")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Export failed: $e")),
      );
    }
  }

  Future<Uint8List> _resizeImage(Uint8List originalBytes, List<int> claritySize) async {
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) throw Exception("Failed to decode image");

    final clarityImage = img.copyResize(
      decoded,
      width: claritySize[0],
      height: claritySize[1],
      interpolation: img.Interpolation.average,
    );

    final finalExport = img.copyResize(
      clarityImage,
      width: 413,
      height: 531,
      interpolation: img.Interpolation.linear,
    );

    return Uint8List.fromList(img.encodeJpg(finalExport, quality: 100));
  }
}
