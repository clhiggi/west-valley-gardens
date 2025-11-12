import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;

import 'events_page.dart'; // Assuming Event class is in events_page.dart

class FlyersPage extends StatefulWidget {
  final Event event;
  final FirebaseFirestore firestore;
  final ImagePicker imagePicker;

  const FlyersPage({super.key, required this.event, required this.firestore, required this.imagePicker});

  @override
  _FlyersPageState createState() => _FlyersPageState();
}

class _FlyersPageState extends State<FlyersPage> {
  late Event _currentEvent;
  bool _isUploading = false;
  StreamSubscription<DocumentSnapshot>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    // Listen for real-time updates to the event document
    _eventSubscription = widget.firestore
        .collection('events')
        .doc(_currentEvent.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _currentEvent = Event.fromFirestore(snapshot);
        });
      }
    });
  }

  @override
  void dispose() {
    _eventSubscription?.cancel(); // Important: cancel the subscription to avoid memory leaks
    super.dispose();
  }

  Future<void> _pickAndUploadFlyer() async {
    final XFile? image = await widget.imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null || _currentEvent.id == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final ref = FirebaseStorage.instance.ref().child('flyers/${_currentEvent.id}.jpg');
      final Uint8List bytes = await image.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();

      // Update the document in Firestore. The stream listener will automatically
      // update the UI, so no setState is needed here.
      await widget.firestore.collection('events').doc(_currentEvent.id).update({
        'flyerUrl': url,
        'flyerPath': ref.fullPath,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flyer uploaded successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e, s) {
      developer.log('Flyer upload failed', name: 'flyers_page', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flyer upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFlyer = _currentEvent.flyerUrl != null && _currentEvent.flyerUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentEvent.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasFlyer)
                Expanded(
                  child: InteractiveViewer(
                    child: Image.network(
                      _currentEvent.flyerUrl!,
                      key: ValueKey(_currentEvent.flyerUrl!), // Add a key to ensure widget updates
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stack) {
                        return const Center(child: Icon(Icons.error, color: Colors.red, size: 50));
                      },
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                    const SizedBox(height: 24),
                    const Text(
                      'No Flyer Available',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A flyer has not been uploaded for this event yet. Would you like to upload one?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 32),
                    _isUploading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Flyer'),
                            onPressed: _pickAndUploadFlyer,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
