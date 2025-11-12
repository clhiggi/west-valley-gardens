// lib/screens/events_page.dart
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final List<String> rsvpList;
  final String? flyerUrl;
  final String? flyerPath;

  Event({
    required this.id,
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
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Event(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
      rsvpList: List<String>.from(data['rsvpList'] as List<dynamic>? ?? []),
      flyerUrl: data['flyerUrl'] as String?,
      flyerPath: data['flyerPath'] as String?,
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
  final LinkedHashMap<DateTime, List<Event>> _events = LinkedHashMap();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _listen();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _listen() {
    widget.firestore.collection('events').orderBy('startTime').snapshots().listen((snap) {
      final list = snap.docs.map((d) => Event.fromFirestore(d)).toList();
      _events
        ..clear()
        ..addAll(_groupByDay(list));
      _selectedEvents.value = _getEventsForDay(_selectedDay ?? _focusedDay);
      if (mounted) setState(() {});
    }, onError: (e, s) {
      developer.log('events listen error', error: e, stackTrace: s);
    });
  }

  Map<DateTime, List<Event>> _groupByDay(List<Event> list) {
    final map = <DateTime, List<Event>>{};
    for (final e in list) {
      final key = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
      map.putIfAbsent(key, () => []).add(e);
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
    final evs = _getEventsForDay(selectedDay);
    if (evs.isEmpty) await _showAddEventDialog(selectedDay);
  }

  Future<void> _showAddEventDialog(DateTime selectedDay) async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final loc = TextEditingController();
    TimeOfDay? start;
    TimeOfDay? end;
    XFile? flyer;

    Future<TimeOfDay?> pick(TimeOfDay? i) => showTimePicker(context: context, initialTime: i ?? const TimeOfDay(hour: 12, minute: 0));

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Event'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: title, maxLength: 40, decoration: const InputDecoration(labelText: 'Title'),),
            TextFormField(controller: desc, maxLength: 80, decoration: const InputDecoration(labelText: 'Description'),),
            TextFormField(controller: loc, maxLength: 40, decoration: const InputDecoration(labelText: 'Location'),),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: StatefulBuilder(builder: (c, s) {
                return ElevatedButton(onPressed: () async { final p = await pick(start); if (p != null) s(() => start = p); }, child: Text(start == null ? 'Pick Start' : 'Start: ${start!.format(context)}'));
              })),
              const SizedBox(width: 8),
              Expanded(child: StatefulBuilder(builder: (c, s) {
                return ElevatedButton(onPressed: () async { final p = await pick(end); if (p != null) s(() => end = p); }, child: Text(end == null ? 'Pick End' : 'End: ${end!.format(context)}'));
              })),
            ]),
            const SizedBox(height: 8),
            ElevatedButton.icon(icon: const Icon(Icons.image_outlined), label: const Text('Choose Flyer (optional)'), onPressed: () async {
              final picked = await widget.imagePicker.pickImage(source: ImageSource.gallery);
              if (picked != null) flyer = picked;
            }),
            if (flyer != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('Selected: ${flyer!.name}', style: const TextStyle(fontSize: 12))),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (title.text.trim().isEmpty || desc.text.trim().isEmpty || loc.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title, description and location are required')));
              return;
            }
            if (start == null || end == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please pick start and end times')));
              return;
            }
            final sDT = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, start!.hour, start!.minute);
            final eDT = DateTime(selectedDay.year, selectedDay.month, selectedDay.day, end!.hour, end!.minute);
            if (!eDT.isAfter(sDT)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End must be after start'))); return; }
            Navigator.of(ctx).pop({'title': title.text.trim(), 'desc': desc.text.trim(), 'loc': loc.text.trim(), 'start': sDT, 'end': eDT, 'flyer': flyer});
          }, child: const Text('Save')),
        ],
      ),
    );

    if (result == null) return;
    final doc = await widget.firestore.collection('events').add({
      'title': result['title'],
      'description': result['desc'],
      'location': result['loc'],
      'startTime': Timestamp.fromDate((result['start'] as DateTime).toUtc()),
      'endTime': Timestamp.fromDate((result['end'] as DateTime).toUtc()),
      'rsvpList': <String>[],
      'flyerUrl': null,
      'flyerPath': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final XFile? chosenFlyer = result['flyer'] as XFile?;
    if (chosenFlyer != null) await _uploadFlyerAndAttach(doc.id, chosenFlyer);
  }

  Future<void> _uploadFlyerAndAttach(String eventId, XFile file) async {
    try {
      final ref = FirebaseStorage.instance.ref('flyers/$eventId.jpg');
      final bytes = await file.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      await widget.firestore.collection('events').doc(eventId).update({'flyerUrl': url, 'flyerPath': ref.fullPath});
      // fetch updated document once for immediate UI feedback
      final snap = await widget.firestore.collection('events').doc(eventId).get();
      final updated = Event.fromFirestore(snap);
      _upsertLocal(updated);
    } catch (e, s) {
      developer.log('uploadFlyer failed', error: e, stackTrace: s);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flyer upload failed')));
    }
  }

  void _upsertLocal(Event updated) {
    final key = DateTime(updated.startTime.year, updated.startTime.month, updated.startTime.day);
    final list = _events.putIfAbsent(key, () => []);
    final i = list.indexWhere((e) => e.id == updated.id);
    if (i >= 0) {
      list[i] = updated;
    } else {
      list.add(updated);
    }
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    if (_selectedDay != null && isSameDay(_selectedDay, key)) {
      _selectedEvents.value = List<Event>.from(_getEventsForDay(_selectedDay!));
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickAndUploadFor(Event ev) async {
    final file = await widget.imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await _uploadFlyerAndAttach(ev.id, file);
  }

  Future<void> _editEvent(Event ev) async {
    final titleCtl = TextEditingController(text: ev.title);
    final descCtl = TextEditingController(text: ev.description);
    final locCtl = TextEditingController(text: ev.location);
    TimeOfDay start = TimeOfDay.fromDateTime(ev.startTime);
    TimeOfDay end = TimeOfDay.fromDateTime(ev.endTime);

    final res = await showDialog<String?>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit Event'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: titleCtl, maxLength: 40, decoration: const InputDecoration(labelText: 'Title')),
            TextFormField(controller: descCtl, maxLength: 80, decoration: const InputDecoration(labelText: 'Description')),
            TextFormField(controller: locCtl, maxLength: 40, decoration: const InputDecoration(labelText: 'Location')),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: () async { final s = await showTimePicker(context: context, initialTime: start); if (s != null) setState(() => start = s); }, child: Text('Start: ${start.format(context)}'))),
              const SizedBox(width: 8),
              Expanded(child: ElevatedButton(onPressed: () async { final e = await showTimePicker(context: context, initialTime: end); if (e != null) setState(() => end = e); }, child: Text('End: ${end.format(context)}'))),
            ]),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(null), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(c).pop('delete'), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ElevatedButton(onPressed: () => Navigator.of(c).pop('save'), child: const Text('Save')),
        ],
      ),
    );

    if (res == 'save') {
      final sDT = DateTime(ev.startTime.year, ev.startTime.month, ev.startTime.day, start.hour, start.minute);
      final eDT = DateTime(ev.endTime.year, ev.endTime.month, ev.endTime.day, end.hour, end.minute);
      await widget.firestore.collection('events').doc(ev.id).update({
        'title': titleCtl.text.trim(),
        'description': descCtl.text.trim(),
        'location': locCtl.text.trim(),
        'startTime': Timestamp.fromDate(sDT.toUtc()),
        'endTime': Timestamp.fromDate(eDT.toUtc()),
      });
    } else if (res == 'delete') {
      final conf = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
        title: const Text('Confirm'),
        content: const Text('Delete this event?'),
        actions: [TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red)))],
      ));
      if (conf == true) {
        await widget.firestore.collection('events').doc(ev.id).delete();
        if (ev.flyerPath != null) {
          try { await FirebaseStorage.instance.ref(ev.flyerPath!).delete(); } catch (e) { developer.log('delete flyer error', error: e); }
        }
      }
    }
  }

  Future<void> _handleRsvp(Event ev) async {
    final ctl = TextEditingController();
    final joined = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('RSVP for "${ev.title}"'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [ const Text('Enter your ASUrite ID'), TextField(controller: ctl) ]),
        actions: [ TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')), ElevatedButton(onPressed: () { if (ctl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ASUrite ID required'))); return; } Navigator.of(context).pop(true); }, child: const Text('Attend')) ],
      ),
    );
    if (joined == true) {
      final id = ctl.text.trim();
      final doc = widget.firestore.collection('events').doc(ev.id);
      final snap = await doc.get();
      final data = snap.data() ?? {};
      final list = List<String>.from(data['rsvpList'] as List<dynamic>? ?? []);
      if (!list.contains(id)) await doc.update({'rsvpList': FieldValue.arrayUnion([id])});
    }
  }

  Widget _dayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    final ev = _getEventsForDay(day);
    if (ev.isNotEmpty) {
      final isSelected = isSameDay(_selectedDay, day);
      final isToday = isSameDay(DateTime.now(), day);
      final bg = isSelected ? Colors.green[600] : (isToday ? Colors.green[200] : Colors.transparent);
      return Center(child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: bg == Colors.transparent ? Colors.transparent : bg), padding: const EdgeInsets.all(6), child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1B5E20))))); 
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events Calendar')),
      body: Column(children: [
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
          daysOfWeekStyle: const DaysOfWeekStyle(weekdayStyle: TextStyle(color: Color(0xFF9CCC65), fontWeight: FontWeight.w600), weekendStyle: TextStyle(color: Color(0xFF9CCC65), fontWeight: FontWeight.w600)),
          calendarStyle: CalendarStyle(todayDecoration: BoxDecoration(color: Colors.green[200], shape: BoxShape.circle), selectedDecoration: BoxDecoration(color: Colors.green[600], shape: BoxShape.circle), markerSize: 0),
          calendarBuilders: CalendarBuilders(defaultBuilder: (c, day, f) => _dayBuilder(c, day, f), markerBuilder: (_, __, ___) => null),
          onFormatChanged: (fmt) { if (_calendarFormat != fmt) setState(() => _calendarFormat = CalendarFormat.month); },
        ),
        const SizedBox(height: 8),
        Expanded(child: ValueListenableBuilder<List<Event>>(valueListenable: _selectedEvents, builder: (ctx, list, _) {
          if (list.isEmpty) return Center(child: Padding(padding: const EdgeInsets.all(24.0), child: Text('No events. Tap an empty day to add one.', style: TextStyle(color: Colors.grey[700]))));
          return ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), itemCount: list.length, itemBuilder: (ctx, i) {
            final ev = list[i];
            final hasFlyer = ev.flyerUrl != null && ev.flyerUrl!.isNotEmpty;
            final color = hasFlyer ? Colors.green[300] : Colors.green[100];
            return GestureDetector(
              onTap: hasFlyer ? () => GoRouter.of(context).go('/flyers', extra: ev.flyerUrl) : null,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(ev.title, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                    IconButton(icon: const Icon(Icons.edit, color: Color(0xFF1B5E20)), onPressed: () => _editEvent(ev)),
                  ]),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(ev.description, overflow: TextOverflow.ellipsis)),
                    Column(children: [
                      IconButton(icon: Icon(hasFlyer ? Icons.image : Icons.upload_file, color: const Color(0xFF1B5E20)), onPressed: () => hasFlyer ? GoRouter.of(context).go('/flyers', extra: ev.flyerUrl) : _pickAndUploadFor(ev)),
                      if (hasFlyer) Container(width: 56, height: 56, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), image: DecorationImage(image: NetworkImage(ev.flyerUrl!), fit: BoxFit.cover))),
                    ]),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Row(children: [ const Icon(Icons.access_time, size: 16, color: Color(0xFF1B5E20)), const SizedBox(width: 6), Text('${DateFormat('h:mm a').format(ev.startTime)} - ${DateFormat('h:mm a').format(ev.endTime)}'), const SizedBox(width: 12), const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF1B5E20)), const SizedBox(width: 6), Flexible(child: Text(ev.location, overflow: TextOverflow.ellipsis)) ])),
                    Row(children: [ Text('${ev.rsvpList.length}', style: const TextStyle(fontWeight: FontWeight.bold)), IconButton(icon: const Icon(Icons.how_to_reg, color: Color(0xFF1B5E20)), onPressed: () => _handleRsvp(ev)) ]),
                  ]),
                ])),
              ),
            );
          });
        })),
      ]),
    );
  }
}
