import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class PrescriptionUploadPage extends StatefulWidget {
  @override
  _PrescriptionUploadPageState createState() => _PrescriptionUploadPageState();
}

class _PrescriptionUploadPageState extends State<PrescriptionUploadPage> {
  List<File> _selectedImages = [];
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  void _chooseFromGallery() async {
    setState(() => _isLoading = true);
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        List<File> validFiles = [];

        for (var file in pickedFiles) {
          final File imageFile = File(file.path);
          final int fileSize = imageFile.lengthSync();
          if (fileSize <= 10 * 1024 * 1024) {
            validFiles.add(imageFile);
          } else {
            _showConfirmationSnackbar("One or more files exceed 10MB and were not added.");
          }
        }

        if (validFiles.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(validFiles);
          });
          _showConfirmationSnackbar("Prescriptions uploaded successfully!");
        } else {
          _showConfirmationSnackbar("No valid image selected (all exceeded 10MB).");
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

  void _showConfirmationSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade600,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showFullImageDialog(BuildContext context, File imageFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            child: InteractiveViewer(
              child: Image.file(imageFile, fit: BoxFit.contain),
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
      final Uri whatsappUrl = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green[400],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Text(
          'Upload Your Prescription',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
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
              onPressed: () {
                // Navigate to Cart page if needed
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUploadSection(),
              const SizedBox(height: 10),

              // Display selected images if any
              if (_selectedImages.isNotEmpty) _buildImageGrid(),
              const SizedBox(height: 10),

              // Submit button (enabled only if images are selected)
              ElevatedButton.icon(
                onPressed: (_selectedImages.isEmpty || _isLoading) ? null : _submitPrescription,
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text("Submit Prescription"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  shadowColor: Colors.green.shade200,
                ),
              ),
              const SizedBox(height: 20),
              _buildRequirementsSection(),
              _buildSamplePrescriptionSection(),
              _buildWarningSection(),
            ],
          ),
        ),
      ),

      backgroundColor: Colors.green.shade50,
    );
  }

  Widget _buildUploadSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.upload, size: 24, color: Colors.green.shade700),
                SizedBox(width: 10),
                Text(
                  "Upload Prescription(s)",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _chooseFromGallery,
              icon: _isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Icon(Icons.image, size: 24),
              label: Text(
                "Choose from Gallery",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: Colors.green.shade200,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "Supported formats: JPG, PNG",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => _showFullImageDialog(context, _selectedImages[index]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_selectedImages[index], fit: BoxFit.cover),
              ),
            ),
            Positioned(
              right: 0,
              child: IconButton(
                icon: Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _deleteImage(index),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequirementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Prescription Requirements:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.green.shade600)),
        Wrap(spacing: 3, children: [
          _infoChip("Doctor Details", Icons.person),
          _infoChip("Date of Prescription", Icons.date_range),
          _infoChip("Patient Details", Icons.account_circle),
          _infoChip("Medicine Details", Icons.medication),
          _infoChip("Max File Size: 10MB", Icons.upload_file),
        ]),
      ],
    );
  }

  Widget _infoChip(String text, IconData icon) => Chip(label: Text(text), avatar: Icon(icon, color: Colors.green.shade700));

  Widget _buildSamplePrescriptionSection() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Sample Prescription:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.green.shade600,
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showFullImageDialog(context, File("assets/images/prescriptionsample.png")),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  "assets/images/prescriptionsample.png",
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSection() {
    return Row(
      children: [
        Icon(Icons.warning, color: Colors.orange),
        Expanded(
          child: Text(
            "Our pharmacist will dispense medicines only if the prescription is valid & meets all government regulations.",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}