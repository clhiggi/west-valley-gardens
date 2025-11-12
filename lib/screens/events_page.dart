import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'flyers_page.dart';

class Event {
  final String? id;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> rsvpList;
  final String? flyerUrl;
  final String? flyerPath;

  Event({
    this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.rsvpList,
    this.flyerUrl,
    this.flyerPath,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return Event(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
      rsvpList: List<String>.from(data['rsvpList'] as List<dynamic>? ?? <String>[]),
      flyerUrl: data['flyerUrl'] as String?,
      flyerPath: data['flyerPath'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'location': location,
        'startTime': Timestamp.fromDate(startTime.toUtc()),
        'endTime': Timestamp.fromDate(endTime.toUtc()),
        'rsvpList': rsvpList,
        'flyerUrl': flyerUrl,
        'flyerPath': flyerPath,
      };

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? rsvpList,
    String? flyerUrl,
    String? flyerPath,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      rsvpList: rsvpList ?? List<String>.from(this.rsvpList),
      flyerUrl: flyerUrl ?? this.flyerUrl,
      flyerPath: flyerPath ?? this.flyerPath,
    );
  }
}

class EventsPage extends StatefulWidget {
  const EventsPage({
    super.key,
    required this.firestore,
    required this.imagePicker,
  });

  final FirebaseFirestore firestore;
  final ImagePicker imagePicker;

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Map<DateTime, List<Event>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _listenToEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _listenToEvents() {
    widget.firestore.collection('events').orderBy('startTime').snapshots().listen((snapshot) {
      final events = snapshot.docs.map((d) => Event.fromFirestore(d)).toList();
      _events
        ..clear()
        ..addAll(_groupByDay(events));
      _selectedEvents.value = _getEventsForDay(_selectedDay ?? _focusedDay);
      if (mounted) setState(() {});
    }, onError: (e, s) {
      developer.log('Failed to listen to events', name: 'events_page', error: e, stackTrace: s);
    });
  }

  Map<DateTime, List<Event>> _groupByDay(List<Event> events) {
    final map = <DateTime, List<Event>>{};
    for (final e in events) {
      final day = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
      map.putIfAbsent(day, () => []).add(e);
    }
    for (final k in map.keys) {
      map[k]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return map;
  }

  List<Event> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }

    if (_getEventsForDay(selectedDay).isEmpty) {
      await _showAddEventDialog(selectedDay);
    }
  }

  Future<void> _showAddEventDialog(DateTime selectedDay) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    XFile? flyerFile;
    final formKey = GlobalKey<FormState>();

    Future<TimeOfDay?> pickTime(TimeOfDay? initial) {
      return showTimePicker(context: context, initialTime: initial ?? const TimeOfDay(hour: 12, minute: 0));
    }

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: StatefulBuilder(builder: (ctx, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title (max 40)'),
                      maxLength: 40,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description (max 80)'),
                      maxLength: 80,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location (max 40)'),
                      maxLength: 40,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final chosen = await pickTime(startTime);
                              if (chosen != null) setState(() => startTime = chosen);
                            },
                            child: Text(startTime == null ? 'Pick Start' : 'Start: ${startTime!.format(context)}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final chosen = await pickTime(endTime);
                              if (chosen != null) setState(() => endTime = chosen);
                            },
                            child: Text(endTime == null ? 'Pick End' : 'End: ${endTime!.format(context)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Choose Flyer (optional)'),
                      onPressed: () async {
                        final XFile? picked = await widget.imagePicker.pickImage(source: ImageSource.gallery);
                        if (picked != null) setState(() => flyerFile = picked);
                      },
                    ),
                    if (flyerFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Selected: ${flyerFile!.name}', style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                );
              }),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  if (startTime == null || endTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick start and end times')));
                    return;
                  }
                  final startDT = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, startTime!.hour, startTime!.minute);
                  final endDT = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, endTime!.hour, endTime!.minute);
                  if (!endDT.isAfter(startDT)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End must be after start')));
                    return;
                  }
                  Navigator.of(ctx).pop({
                    'title': titleController.text.trim(),
                    'description': descController.text.trim(),
                    'location': locationController.text.trim(),
                    'startDT': startDT,
                    'endDT': endDT,
                    'flyer': flyerFile,
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    final String title = result['title'] as String;
    final String description = result['description'] as String;
    final String location = result['location'] as String;
    final DateTime startDT = result['startDT'] as DateTime;
    final DateTime endDT = result['endDT'] as DateTime;
    final XFile? chosenFlyer = result['flyer'] as XFile?;

    final docRef = await widget.firestore.collection('events').add({
      'title': title,
      'description': description,
      'location': location,
      'startTime': Timestamp.fromDate(startDT.toUtc()),
      'endTime': Timestamp.fromDate(endDT.toUtc()),
      'rsvpList': <String>[],
      'flyerUrl': null,
      'flyerPath': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (chosenFlyer != null) {
      await _uploadFlyerAndAttach(docRef.id, chosenFlyer);
    }
  }

  Future<void> _uploadFlyerAndAttach(String eventId, XFile image) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('flyers/$eventId.jpg');
      final Uint8List bytes = await image.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();
      await widget.firestore.collection('events').doc(eventId).update({
        'flyerUrl': url,
        'flyerPath': ref.fullPath,
      });

      final snap = await widget.firestore.collection('events').doc(eventId).get();
      final updated = Event.fromFirestore(snap);
      _upsertLocalEvent(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flyer uploaded'), backgroundColor: Colors.green));
      }
    } catch (e, s) {
      developer.log('Upload error', name: 'events_page', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flyer upload failed'), backgroundColor: Colors.red));
      }
    }
  }

  void _upsertLocalEvent(Event updated) {
    final dayKey = DateTime(updated.startTime.year, updated.startTime.month, updated.startTime.day);
    final list = _events.putIfAbsent(dayKey, () => []);
    final idx = list.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
    } else {
      list.add(updated);
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    if (_selectedDay != null && isSameDay(_selectedDay, dayKey)) {
      final newSelected = List<Event>.from(_selectedEvents.value);
      final selIdx = newSelected.indexWhere((e) => e.id == updated.id);
      if (selIdx != -1) {
        newSelected[selIdx] = updated;
      } else {
        newSelected.add(updated);
        newSelected.sort((a, b) => a.startTime.compareTo(b.startTime));
      }
      _selectedEvents.value = newSelected;
    }

    if (mounted) setState(() {});
  }

  Future<void> _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && event.id != null) {
      try {
        if (event.flyerPath != null && event.flyerPath!.isNotEmpty) {
          await FirebaseStorage.instance.ref().child(event.flyerPath!).delete();
        }
        await widget.firestore.collection('events').doc(event.id).delete();

        // Remove the event from the local list
        final dayKey = DateTime(event.startTime.year, event.startTime.month, event.startTime.day);
        _events[dayKey]?.removeWhere((e) => e.id == event.id);
        if (_events[dayKey]?.isEmpty ?? false) {
          _events.remove(dayKey);
        }
        _selectedEvents.value = _getEventsForDay(_selectedDay ?? _focusedDay);
        if (mounted) setState(() {});

      } catch (e, s) {
        developer.log('Delete error', name: 'events_page', error: e, stackTrace: s);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete event'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _editEvent(Event event) async {
    final titleController = TextEditingController(text: event.title);
    final descController = TextEditingController(text: event.description);
    final locationController = TextEditingController(text: event.location);
    TimeOfDay? startTime = TimeOfDay.fromDateTime(event.startTime);
    TimeOfDay? endTime = TimeOfDay.fromDateTime(event.endTime);
    final formKey = GlobalKey<FormState>();

    Future<TimeOfDay?> pickTime(TimeOfDay? initial) {
      return showTimePicker(context: context, initialTime: initial ?? const TimeOfDay(hour: 12, minute: 0));
    }

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Event'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: StatefulBuilder(builder: (ctx, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title (max 40)'),
                      maxLength: 40,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description (max 80)'),
                      maxLength: 80,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location (max 40)'),
                      maxLength: 40,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final chosen = await pickTime(startTime);
                              if (chosen != null) setState(() => startTime = chosen);
                            },
                            child: Text(startTime == null ? 'Pick Start' : 'Start: ${startTime!.format(context)}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final chosen = await pickTime(endTime);
                              if (chosen != null) setState(() => endTime = chosen);
                            },
                            child: Text(endTime == null ? 'Pick End' : 'End: ${endTime!.format(context)}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                _deleteEvent(event);
                Navigator.of(ctx).pop(null);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  if (startTime == null || endTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick start and end times')));
                    return;
                  }
                  final startDT = DateTime(event.startTime.year, event.startTime.month, event.startTime.day, startTime!.hour, startTime!.minute);
                  final endDT = DateTime(event.startTime.year, event.startTime.month, event.startTime.day, endTime!.hour, endTime!.minute);
                  if (!endDT.isAfter(startDT)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End must be after start')));
                    return;
                  }
                  Navigator.of(ctx).pop({
                    'title': titleController.text.trim(),
                    'description': descController.text.trim(),
                    'location': locationController.text.trim(),
                    'startDT': startDT,
                    'endDT': endDT,
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null || event.id == null) return;

    await widget.firestore.collection('events').doc(event.id).update({
      'title': result['title'],
      'description': result['description'],
      'location': result['location'],
      'startTime': Timestamp.fromDate((result['startDT'] as DateTime).toUtc()),
      'endTime': Timestamp.fromDate((result['endDT'] as DateTime).toUtc()),
    });
  }

  Future<void> _handleRsvp(Event event) async {
    final rsvpController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('RSVP'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: rsvpController,
              decoration: const InputDecoration(labelText: 'ASUrite ID'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your ASUrite ID';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(rsvpController.text.trim());
                }
              },
              child: const Text('Attend'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && event.id != null) {
      if (event.rsvpList.contains(result)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You have already RSVP'd to this event."), backgroundColor: Colors.orange),
        );
        return;
      }
      await widget.firestore.collection('events').doc(event.id).update({
        'rsvpList': FieldValue.arrayUnion([result]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events Calendar')),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            onDaySelected: _onDaySelected,
            onPageChanged: (d) => setState(() => _focusedDay = d),
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              weekendStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.green[200], shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.green[600], shape: BoxShape.circle),
              defaultTextStyle: const TextStyle(color: Colors.black),
              weekendTextStyle: const TextStyle(color: Colors.black),
              outsideTextStyle: const TextStyle(color: Colors.grey),
              markerDecoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              markerMargin: const EdgeInsets.only(top: 5, right: 1, left: 1),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green[800],
                      ),
                      width: 7.0,
                      height: 7.0,
                    ),
                  );
                }
                return null;
              },
            ),
            onFormatChanged: (format) {
              if (_calendarFormat != format) setState(() => _calendarFormat = CalendarFormat.month);
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (ctx, events, _) {
                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('No events. Tap an empty day to add one.', style: TextStyle(color: Colors.grey[700])),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: events.length,
                  itemBuilder: (ctx, i) {
                    final ev = events[i];
                    final hasFlyer = ev.flyerUrl != null && ev.flyerUrl!.isNotEmpty;
                    final cardColor = hasFlyer ? Colors.green[300] : Colors.green[100];

                    return Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.go('/events/flyers', extra: ev),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: Text(ev.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                  IconButton(icon: const Icon(Icons.edit, color: Color(0xFF1B5E20)), onPressed: () => _editEvent(ev)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: Text(ev.description, maxLines: 2, overflow: TextOverflow.ellipsis)),
                                  IconButton(icon: const Icon(Icons.how_to_reg, color: Color(0xFF1B5E20)), onPressed: () => _handleRsvp(ev)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(children: [
                                      const Icon(Icons.access_time, size: 16, color: Color(0xFF1B5E20)),
                                      const SizedBox(width: 6),
                                      Text('${DateFormat('h:mm a').format(ev.startTime)} - ${DateFormat('h:mm a').format(ev.endTime)}'),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF1B5E20)),
                                      const SizedBox(width: 6),
                                      Flexible(child: Text(ev.location, overflow: TextOverflow.ellipsis)),
                                    ]),
                                  ),
                                  Text('${ev.rsvpList.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
