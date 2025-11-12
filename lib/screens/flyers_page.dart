import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;

import 'events_page.dart'; // assumes Event and Event.fromFirestore(Map<String, dynamic>) are defined here

class FlyersPage extends StatefulWidget {
  final Event event;
  final FirebaseFirestore firestore;
  final ImagePicker imagePicker;

  const FlyersPage({
    super.key,
    required this.event,
    required this.firestore,
    required this.imagePicker,
  });

  @override
  _FlyersPageState createState() => _FlyersPageState();
}

class _FlyersPageState extends State<FlyersPage> {
  late Event _currentEvent;
  bool _isUploading = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;

    // Listen for real-time updates to the event document
    _eventSubscription = widget.firestore
        .collection('events')
        .doc(_currentEvent.id)
        .snapshots()
        .listen((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (!mounted) return;
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          // Assumes Event.fromFirestore accepts Map<String, dynamic>
          setState(() {
            _currentEvent = Event.fromFirestore(data as DocumentSnapshot<Object?>);
          });
        }
      }
    }, onError: (err, stack) {
      developer.log('Error listening to event doc', name: 'flyers_page', error: err, stackTrace: stack);
    });
  }

  @override
  void dispose() {
    // Cancel subscription to avoid memory leaks
    _eventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _pickAndUploadFlyer() async {
    // Pick an image from the gallery
    final XFile? image = await widget.imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final String? eventId = _currentEvent.id;
    if (eventId!.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final ref = FirebaseStorage.instance.ref().child('flyers/$eventId.jpg');
      final Uint8List bytes = await image.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // Upload bytes
      final uploadTask = ref.putData(bytes, metadata);
      await uploadTask.whenComplete(() {});

      // Get URL
      final url = await ref.getDownloadURL();

      // Update Firestore document with flyer URL/path
      await widget.firestore.collection('events').doc(eventId).update({
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          // Use Column with Expanded children to avoid overflow on small screens
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: hasFlyer
                      ? Column(
                          children: [
                            Expanded(
                              child: InteractiveViewer(
                                child: Image.network(
                                  _currentEvent.flyerUrl!,
                                  key: ValueKey(_currentEvent.flyerUrl),
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stack) {
                                    return const Center(
                                      child: Icon(Icons.error, color: Colors.red, size: 50),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _isUploading
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: CircularProgressIndicator(),
                                  )
                                : ElevatedButton.icon(
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Upload New Flyer'),
                                    onPressed: _pickAndUploadFlyer,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      textStyle: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                          ],
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
