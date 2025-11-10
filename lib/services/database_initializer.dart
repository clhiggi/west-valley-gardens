import 'package:firebase_database/firebase_database.dart';

class DatabaseInitializer {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  void initializeData() {
    _database.child('pollinator_data').set({
      'WV_Gardens': {
        'ants': 20,
        'beetles': 20,
        'butterflies': 20,
        'flies': 20,
        'honeybees': 20,
        'Moths': 20,
        'Wasps': 20,
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
  }
}
