import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String? id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String? flyerUrl;
  final String? flyerPath;
  final List<String> rsvpList;

  Event({
    this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.flyerUrl,
    this.flyerPath,
    this.rsvpList = const [],
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      flyerUrl: data['flyerUrl'],
      flyerPath: data['flyerPath'],
      rsvpList: List<String>.from(data['rsvpList'] ?? []),
    );
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? flyerUrl,
    String? flyerPath,
    List<String>? rsvpList,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      flyerUrl: flyerUrl ?? this.flyerUrl,
      flyerPath: flyerPath ?? this.flyerPath,
      rsvpList: rsvpList ?? this.rsvpList,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'flyerUrl': flyerUrl,
      'flyerPath': flyerPath,
      'rsvpList': rsvpList,
    };
  }
}
