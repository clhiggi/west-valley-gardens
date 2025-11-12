import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/report_problem_dialog.dart';
import 'dart:developer' as developer;

class ProblemsPage extends StatefulWidget {
  const ProblemsPage({super.key});

  @override
  _ProblemsPageState createState() => _ProblemsPageState();
}

class _ProblemsPageState extends State<ProblemsPage> {
  final _picker = ImagePicker();

  Future<void> _showUploadDialog(XFile imageFile) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ReportProblemDialog(
          imageFile: imageFile,
          onUpload: _uploadProblem,
        );
      },
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Problem reported successfully! Image uploaded.')),
      );
      // Use a timer to allow the user to see the message before navigating
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          context.go('/'); // Navigate back to the home page or a relevant page
        }
      });
    }
  }

  Future<void> _getImageAndUpload(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      await _showUploadDialog(pickedFile);
    }
  }

  Future<bool> _uploadProblem(XFile imageFile, String description) async {
    if (description.trim().isEmpty) {
      // This case is handled in the dialog, but as a fallback:
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a description.')),
        );
      }
      return false;
    }

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('problem_images')
          .child('${DateTime.now().toIso8601String()}.jpg');

      final bytes = await imageFile.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      await storageRef.putData(bytes, metadata);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('problems').add({
        'imageUrl': imageUrl,
        'description': description,
        'timestamp': Timestamp.now(),
        'status': 'reported',
      });

      return true;
    } catch (e, s) {
      developer.log('Error uploading problem', name: 'problems_page', error: e, stackTrace: s);
      return false; // The dialog will handle showing the error message
    }
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle bodyTextStyle = TextStyle(
      fontSize: 16.0,
      color: Colors.black,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('See a problem? Let us know!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => context.go('/problems/list'),
            tooltip: 'View Full List',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "We rely on our visitors to help us keep West Valley Gardens thriving. By observing and reporting issues such as wilting plants, pests, or irrigation leaks, visitors become vital partners in maintaining the garden’s health. When guests take photos and share details of what they see, they provide essential, real-time information that supports student leaders in quickly identifying and addressing problems.",
              style: bodyTextStyle,
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadOption(
                  icon: Icons.camera_alt,
                  label: 'Take Photo',
                  onTap: () => _getImageAndUpload(ImageSource.camera),
                ),
                _buildUploadOption(
                  icon: Icons.photo_library,
                  label: 'From Gallery',
                  onTap: () => _getImageAndUpload(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Recently Reported Problems:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 400,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('problems')
                    .orderBy('timestamp', descending: true)
                    .limit(6)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No problems reported yet."),
                    );
                  }

                  final problems = snapshot.data!.docs;

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: problems.length,
                    itemBuilder: (context, index) {
                      final problem = problems[index];
                      final imageUrl = problem['imageUrl'];
                      final description = problem['description'];

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16.0),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption(
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.green[800],
          ),
          const SizedBox(height: 8),
          Text(label)
        ],
      ),
    );
  }
}
