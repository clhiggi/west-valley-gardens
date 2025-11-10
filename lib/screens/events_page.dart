import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  List<Event> _selectedEvents = [];
  int _selectedEventIndex = -1;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEventsFromFirestore();
  }

  void _loadEventsFromFirestore() {
    _firestore.collection('events').snapshots().listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _events = {};
        for (var doc in snapshot.docs) {
          try {
            Event event = Event.fromFirestore(doc);
            DateTime date = DateTime.utc(
              event.startTime.year,
              event.startTime.month,
              event.startTime.day,
            );
            _events.putIfAbsent(date, () => []);
            _events[date]!.add(event);
          } catch (e) {
            // ignore malformed doc or log
            debugPrint('Error parsing event doc ${doc.id}: $e');
          }
        }
        if (_selectedDay != null) {
          _selectedEvents = _getEventsForDay(_selectedDay!);
        }
      });
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _events[dayUtc] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
        _selectedEventIndex = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RSVP for an EVENT'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar<Event>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2035, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              eventLoader: _getEventsForDay,
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.green[800],
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false, // hide format button
                titleCentered: true,
                formatButtonTextStyle:
                    TextStyle(color: Colors.white, fontSize: 14.0),
                formatButtonDecoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      right: 1,
                      bottom: 1,
                      child: _buildEventsMarker(events.length),
                    );
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 8.0),
            _buildEventList(),
            const SizedBox(height: 80.0),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(_selectedDay ?? DateTime.now()),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventsMarker(int count) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green,
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '$count',
          style: const TextStyle(color: Colors.white, fontSize: 12.0),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    if (_selectedEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: Text('No events for this day.')),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedEvents.length,
      itemBuilder: (context, index) {
        final event = _selectedEvents[index];
        final isSelected = _selectedEventIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedEventIndex = index;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green : Colors.green.shade100,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8.0),
                        if (event.description.isNotEmpty)
                          Text(
                            event.description,
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8.0),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.access_time,
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.black54,
                                size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat.jm().format(event.startTime)} - ${DateFormat.jm().format(event.endTime)}',
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 12),
                            ),
                            const SizedBox(width: 16),
                            if (event.location != null &&
                                event.location!.isNotEmpty)
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.location_on,
                                        color: isSelected
                                            ? Colors.white70
                                            : Colors.black54,
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        event.location!,
                                        style: TextStyle(
                                            color: isSelected
                                                ? Colors.white70
                                                : Colors.black54,
                                            fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: 'Edit',
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.edit,
                                color: isSelected ? Colors.white : Colors.green,
                                size: 20),
                            onPressed: () => _showEditEventDialog(event),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Tooltip(
                        message: 'Flyer',
                        child: GestureDetector(
                          onTap: () {
                            if (event.flyerUrl != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FlyerPreviewPage(
                                      flyerUrl: event.flyerUrl!),
                                ),
                              );
                            } else {
                              _addFlyer(event);
                            }
                          },
                          child: event.flyerUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: Image.network(
                                    event.flyerUrl!,
                                    width: 24,
                                    height: 24,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(Icons.add_photo_alternate,
                                  color:
                                      isSelected ? Colors.white : Colors.green,
                                  size: 24),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Tooltip(
                        message: 'RSVP',
                        child: GestureDetector(
                          onTap: () => _showRsvpDialog(event),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                event.rsvpList.length.toString(),
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.how_to_reg,
                                  color:
                                      isSelected ? Colors.white : Colors.green,
                                  size: 24),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddEventDialog(DateTime selectedDay) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime =
        TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Add Event'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    maxLength: 40,
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLength: 80,
                  ),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    maxLength: 25,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Start: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (picked != null) {
                            setStateDialog(() => startTime = picked);
                          }
                        },
                        child: Text(startTime.format(context),
                            style: const TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('End: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (picked != null) {
                            setStateDialog(() => endTime = picked);
                          }
                        },
                        child: Text(endTime.format(context),
                            style: const TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.green)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Add', style: TextStyle(color: Colors.green)),
                onPressed: () async {
                  if (titleController.text.isEmpty) return;

                  final newEvent = Event(
                    title: titleController.text,
                    description: descriptionController.text,
                    location: locationController.text.isEmpty
                        ? null
                        : locationController.text,
                    startTime: DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                      startTime.hour,
                      startTime.minute,
                    ),
                    endTime: DateTime(
                      selectedDay.year,
                      selectedDay.month,
                      selectedDay.day,
                      endTime.hour,
                      endTime.minute,
                    ),
                  );

                  await _firestore
                      .collection('events')
                      .add(newEvent.toFirestore());
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditEventDialog(Event event) {
    final titleController = TextEditingController(text: event.title);
    final descriptionController =
        TextEditingController(text: event.description);
    final locationController = TextEditingController(text: event.location);
    TimeOfDay startTime = TimeOfDay.fromDateTime(event.startTime);
    TimeOfDay endTime = TimeOfDay.fromDateTime(event.endTime);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Edit Event'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    maxLength: 40,
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLength: 80,
                  ),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                    maxLength: 25,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Start: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (picked != null) {
                            setStateDialog(() => startTime = picked);
                          }
                        },
                        child: Text(startTime.format(context),
                            style: const TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('End: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (picked != null) {
                            setStateDialog(() => endTime = picked);
                          }
                        },
                        child: Text(endTime.format(context),
                            style: const TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the edit dialog
                  _showDeleteConfirmationDialog(event);
                },
              ),
              TextButton(
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.green)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child:
                    const Text('Update', style: TextStyle(color: Colors.green)),
                onPressed: () async {
                  if (titleController.text.isEmpty) return;

                  final updatedEvent = Event(
                    id: event.id,
                    title: titleController.text,
                    description: descriptionController.text,
                    location: locationController.text.isEmpty
                        ? null
                        : locationController.text,
                    startTime: DateTime(
                      event.startTime.year,
                      event.startTime.month,
                      event.startTime.day,
                      startTime.hour,
                      startTime.minute,
                    ),
                    endTime: DateTime(
                      event.startTime.year,
                      event.startTime.month,
                      event.startTime.day,
                      endTime.hour,
                      endTime.minute,
                    ),
                    flyerUrl: event.flyerUrl,
                    rsvpList: List<String>.from(event.rsvpList),
                  );

                  await _updateEvent(updatedEvent);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.green)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await _deleteEvent(event);
              Navigator.of(context).pop(); // Close the confirmation dialog
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateEvent(Event event) async {
    try {
      await _firestore
          .collection('events')
          .doc(event.id)
          .update(event.toFirestore());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating event: $e')),
        );
      }
    }
  }

  Future<void> _deleteEvent(Event event) async {
    try {
      await _firestore.collection('events').doc(event.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event deleted successfully!')),
        );
      }
      // Reset selection as the event is gone
      setState(() {
        _selectedEventIndex = -1;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting event: $e')),
        );
      }
    }
  }

  Future<void> _addFlyer(Event event) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    try {
      String fileName =
          'flyers/${event.id ?? 'new'}_${DateTime.now().millisecondsSinceEpoch}.png';
      TaskSnapshot snapshot =
          await FirebaseStorage.instance.ref(fileName).putFile(file);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      if (event.id != null) {
        await _firestore
            .collection('events')
            .doc(event.id)
            .update({'flyerUrl': downloadUrl});
      }
    } catch (e) {
      debugPrint('Error uploading flyer: $e');
    }
  }

  void _showRsvpDialog(Event event) {
    final asuRiteIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('RSVP to Event'),
          content: TextField(
            controller: asuRiteIdController,
            decoration: const InputDecoration(labelText: 'ASURITE ID'),
          ),
          actions: [
            TextButton(
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.green)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('RSVP', style: TextStyle(color: Colors.green)),
              onPressed: () {
                final asuRiteId = asuRiteIdController.text.trim();
                if (asuRiteId.isNotEmpty) {
                  _rsvpToEvent(event, asuRiteId);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _rsvpToEvent(Event event, String asuRiteId) async {
    try {
      if (event.rsvpList.contains(asuRiteId)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You have already RSVP\'d to this event.')),
          );
        }
        return;
      }
      if (event.id != null) {
        await _firestore.collection('events').doc(event.id).update({
          'rsvpList': FieldValue.arrayUnion([asuRiteId])
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('RSVP successful!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error RSVP: $e')),
        );
      }
    }
  }
}

class Event {
  final String? id;
  final String title;
  final String description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final String? flyerUrl;
  final List<String> rsvpList;

  Event({
    this.id,
    required this.title,
    required this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    this.flyerUrl,
    this.rsvpList = const [],
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};

    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      // if it's stored as ISO string
      if (value is String) return DateTime.parse(value);
      throw StateError('Unsupported timestamp type: ${value.runtimeType}');
    }

    final start = parseDateTime(data['startTime']);
    final end = parseDateTime(data['endTime']);

    return Event(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      location: data['location'] as String?,
      startTime: start,
      endTime: end,
      flyerUrl: data['flyerUrl'] as String?,
      rsvpList: List<String>.from(data['rsvpList'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'flyerUrl': flyerUrl,
      'rsvpList': rsvpList,
    };
  }
}

class FlyerPreviewPage extends StatelessWidget {
  final String flyerUrl;

  const FlyerPreviewPage({super.key, required this.flyerUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flyer Preview'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(flyerUrl),
        ),
      ),
    );
  }
}
