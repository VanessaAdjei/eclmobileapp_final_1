// pages/prescription.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'homepage.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'AppBackButton.dart';

class PrescriptionUploadPage extends StatefulWidget {
  const PrescriptionUploadPage({super.key});

  @override
  _PrescriptionUploadPageState createState() => _PrescriptionUploadPageState();
}

class _PrescriptionUploadPageState extends State<PrescriptionUploadPage> {
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  void _chooseFromGallery() async {
    setState(() => _isLoading = true);
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        List<File> validFiles = [];
        for (var file in pickedFiles) {
          final File imageFile = File(file.path);
          final int fileSize = imageFile.lengthSync();
          if (fileSize <= 10 * 1024 * 1024) {
            validFiles.add(imageFile);
          } else {
            _showConfirmationSnackbar(
                "One or more files exceed 10MB and were not added.");
          }
        }
        if (validFiles.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(validFiles);
          });
          _showConfirmationSnackbar("Prescriptions uploaded successfully!");
        } else {
          _showConfirmationSnackbar(
              "No valid image selected (all exceeded 10MB).");
        }
      } else {
        _showConfirmationSnackbar("No image selected.");
      }
    } catch (e) {
      _showConfirmationSnackbar("Failed to upload image: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _chooseFromCamera() async {
    setState(() => _isLoading = true);
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final int fileSize = imageFile.lengthSync();
        if (fileSize <= 10 * 1024 * 1024) {
          setState(() {
            _selectedImages.add(imageFile);
          });
          _showConfirmationSnackbar("Prescription uploaded successfully!");
        } else {
          _showConfirmationSnackbar("File exceeds 10MB and was not added.");
        }
      } else {
        _showConfirmationSnackbar("No image captured.");
      }
    } catch (e) {
      _showConfirmationSnackbar("Failed to capture image: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showConfirmationSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade600,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showFullImageDialog(BuildContext context, dynamic image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: image is File
                  ? Image.file(image, fit: BoxFit.contain)
                  : Image.asset(image, fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }

  void _submitPrescription() async {
    if (_selectedImages.isNotEmpty) {
      _showConfirmationSnackbar("Prescription submitted successfully!");
      final String phoneNumber = "+233504518047";
      final String message = "Hello, I am submitting my prescriptions.";
      final Uri whatsappUrl = Uri.parse(
          "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");
      try {
        await launchUrl(whatsappUrl);
        _showConfirmationSnackbar("Opening WhatsApp...");
      } catch (e) {
        _showConfirmationSnackbar("Could not open WhatsApp.");
      }
    } else {
      _showConfirmationSnackbar("Please upload at least one prescription.");
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _showConfirmationSnackbar("Image deleted successfully!");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
        leading: AppBackButton(),
        title: Column(
          children: [
            Text(
              'Upload Prescription',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              'Get your medicines delivered',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green[700],
            ),
            child: IconButton(
              icon: Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildUploadArea(theme),
                  const SizedBox(height: 18),
                  if (_selectedImages.isNotEmpty) _buildImagePreviewList(),
                  const SizedBox(height: 18),
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                  _buildRequirementsCard(),
                  const SizedBox(height: 16),
                  _buildSamplePrescriptionCard(),
                  const SizedBox(height: 16),
                  _buildWarningCard(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: Center(
                child: CircularProgressIndicator(color: Colors.green.shade700),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.green.shade50,
    );
  }

  Widget _buildUploadArea(ThemeData theme) {
    return GestureDetector(
      onTap: _isLoading ? null : _showUploadOptions,
      child: DottedBorder(
        color: Colors.green.shade700,
        strokeWidth: 2,
        borderType: BorderType.RRect,
        radius: Radius.circular(16),
        dashPattern: [8, 4],
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload,
                    size: 40, color: Colors.green.shade700),
                SizedBox(height: 10),
                Text(
                  "Tap to upload prescription",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Supported: JPG, PNG, Max 10MB",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.green.shade700),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _chooseFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Colors.green.shade700),
              title: Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _chooseFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewList() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length,
        separatorBuilder: (context, i) => SizedBox(width: 12),
        itemBuilder: (context, index) {
          final file = _selectedImages[index];
          return Stack(
            children: [
              GestureDetector(
                onTap: () => _showFullImageDialog(context, file),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(file, fit: BoxFit.cover),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _deleteImage(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.18),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: (_selectedImages.isEmpty || _isLoading)
              ? null
              : _submitPrescription,
          icon: FaIcon(
            FontAwesomeIcons.whatsapp,
            color: Colors.white,
            size: 28,
          ),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Text(
              "Submit via WhatsApp",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ).copyWith(
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.green.shade900.withOpacity(0.18);
                }
                return null;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green.shade700),
                SizedBox(width: 8),
                Text("Prescription Requirements",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.green.shade700)),
              ],
            ),
            SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _infoChip("Doctor Details", Icons.person),
              _infoChip("Date of Prescription", Icons.date_range),
              _infoChip("Patient Details", Icons.account_circle),
              _infoChip("Medicine Details", Icons.medication),
              _infoChip("Max File Size: 10MB", Icons.upload_file),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String text, IconData icon) =>
      Chip(label: Text(text), avatar: Icon(icon, color: Colors.green.shade700));

  Widget _buildSamplePrescriptionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Sample Prescription",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showFullImageDialog(
                  context, "assets/images/prescriptionsample.png"),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    "assets/images/prescriptionsample.png",
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.orange.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Our pharmacist will dispense medicines only if the prescription is valid & meets all government regulations.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
