import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'flyer_rsvp_page.dart';

class ImageViewerPage extends StatelessWidget {
  final String flyerId; // Firestore document ID

  const ImageViewerPage({super.key, required this.flyerId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flyer'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: firestore.collection('flyers').doc(flyerId).get(),
        builder: (context, snapshot) {
          // --- Error handling ---
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading flyer.',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }

          // --- Loading indicator ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- Data validation ---
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Flyer not found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final data = snapshot.data!.data();
          final imageUrl = data?['imageUrl'] as String? ?? '';

          // --- Empty image check ---
          if (imageUrl.isEmpty) {
            return const Center(
              child: Text(
                'No image available.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // --- Display image + optional RSVP button ---
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.event_available),
                  label: const Text('RSVP'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FlyerRsvpPage(
                          flyerPath: imageUrl,
                          eventId: flyerId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
