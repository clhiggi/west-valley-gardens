// lib/services/database_initializer.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Initializes baseline pollinator data in Firebase Realtime Database.
/// Call `DatabaseInitializer().initializeData()` once (e.g., after Firebase.initializeApp()).
class DatabaseInitializer {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> initializeData() async {
    try {
      await _database.child('pollinator_data').set({
        'WV_Gardens': {
          'ants': 20,
          'beetles': 20,
          'butterflies': 20,
          'flies': 20,
          'honeybees': 20,
          'moths': 20,
          'wasps': 20,
        },
        'WV_Campus': {
          'ants': 10,
          'beetles': 20,
          'butterflies': 40,
          'flies': 80,
          'honeybees': 40,
          'moths': 20,
          'wasps': 10,
        },
      });
      // Optional: print confirmation for debugging
      if (kDebugMode) {
        print('Pollinator data initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing pollinator data: $e');
      }
    }
  }
}

