import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/claude_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import 'results_screen.dart';

// List of crops the farmer can choose from
const List<String> kCrops = [
  'Mahindi',
  'Nyanya',
  'Maharagwe',
  'Pilipili',
  'Ndizi',
  'Mchele',
  'Muhogo',
  'Pamba',
];

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  String _selectedCrop = 'Mahindi';
  bool _analysing = false;
  String _statusMessage = '';

  final ImagePicker _picker = ImagePicker();

  // Open camera to take a new photo
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // Compress slightly to save data
    );
    if (photo != null) {
      setState(() => _selectedImage = File(photo.path));
    }
  }

  // Pick a photo from the phone gallery
  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (photo != null) {
      setState(() => _selectedImage = File(photo.path));
    }
  }

  // Send the photo to Claude API for analysis
  Future<void> _analysePhoto() async {
    if (_selectedImage == null) return;

    setState(() {
      _analysing = true;
      _statusMessage = 'Inatuma picha kwa Claude AI...';
    });

    // Call Claude API
    final result = await ClaudeService.analyseLeafPhoto(
      imageFile: _selectedImage!,
      cropName: _selectedCrop,
    );

    setState(() => _statusMessage = 'Inahifadhi matokeo...');

    // Save diagnosis to Supabase in the background
    await SupabaseService.saveDiagnosis(
      cropName: _selectedCrop,
      claudeResponse: result,
      photoPath: _selectedImage!.path,
    );

    setState(() => _analysing = false);

    if (!mounted) return;

    // Go to results screen with the diagnosis data
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          diagnosis: result,
          imagePath: _selectedImage!.path,
          cropName: _selectedCrop,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: Text('Piga Picha ya Jani',
            style: GoogleFonts.playfairDisplay(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Crop selector
            const Text(
              'Chagua Zao:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCrop,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: kCrops
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCrop = val);
              },
            ),

            const SizedBox(height: 20),

            // Image preview area
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2E8B57),
                    width: 2,
                  ),
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            size: 60,
                            color: Color(0xFF2E8B57),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Gusa hapa kupiga picha',
                            style: TextStyle(
                              color: Color(0xFF2E8B57),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Two buttons: camera and gallery
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    onPressed: _takePhoto,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A5C2E),
                      side: const BorderSide(color: Color(0xFF1A5C2E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Picha Zilizopo'),
                    onPressed: _pickFromGallery,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1A5C2E),
                      side: const BorderSide(color: Color(0xFF1A5C2E)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Analyse button — only active when image is selected
            if (_analysing)
              Column(
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF1A5C2E),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Color(0xFF1A5C2E)),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.science, size: 22),
                label: const Text(
                  'Chunguza Ugonjwa',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onPressed: _selectedImage == null ? null : _analysePhoto,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _selectedImage == null
                      ? Colors.grey
                      : const Color(0xFF1A5C2E),
                ),
              ),

            const SizedBox(height: 16),

            // Tip for the farmer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Color(0xFFFF6F00)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ushauri: Piga picha karibu na jani ili matokeo yawe sahihi zaidi.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1A1A1A)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
