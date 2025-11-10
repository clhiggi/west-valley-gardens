import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String? id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? flyerUrl;
  final int rsvps;

  Event({
    this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.flyerUrl,
    this.rsvps = 0,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      flyerUrl: data['flyerUrl'],
      rsvps: data['rsvps'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'flyerUrl': flyerUrl,
      'rsvps': rsvps,
    };
  }
}
