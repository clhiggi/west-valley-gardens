import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PausePage extends StatefulWidget {
  const PausePage({super.key});

  @override
  State<PausePage> createState() => _PausePageState();
}

class _PausePageState extends State<PausePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, Map<String, TextEditingController>> _controllers = {};
  final List<String> _pollinators = [
    'Ants',
    'Beetles',
    'Butterflies',
    'Flies',
    'Honeybees',
    'Moths',
    'Wasps'
  ];
  final List<String> _locations = ['West Valley Gardens', 'West Valley Campus'];

  @override
  void initState() {
    super.initState();
    for (var pollinator in _pollinators) {
      _controllers[pollinator] = {};
      for (var location in _locations) {
        _controllers[pollinator]![location] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var pollinator in _pollinators) {
      for (var location in _locations) {
        _controllers[pollinator]![location]?.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _submitData() async {
    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();
    int submissions = 0;

    for (var pollinator in _pollinators) {
      for (var location in _locations) {
        final countText = _controllers[pollinator]![location]!.text;
        if (countText.isNotEmpty) {
          final count = int.tryParse(countText);
          if (count != null && count > 0) {
            submissions++;
            final docRef =
                _firestore.collection('pollinator_observations').doc();
            batch.set(docRef, {
              'pollinator': pollinator,
              'location': location,
              'count': count,
              'timestamp': timestamp,
            });
          }
        }
      }
    }

    if (submissions > 0) {
      try {
        await batch.commit();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Thank you for submitting your observations!')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting data: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data was entered to submit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("West Valley's Pause for Pollinators"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 24.0),
              child: Text(
                'West Valley Gardens is thrilled to launch the Pause for Pollinators initiative, a simple, fun way for students to step outside, take a mindful break, and reconnect with nature. In just 15 minutes, you can watch bees, butterflies, and other pollinators in action, record your observations, and contribute valuable data on the diversity of pollinators at West Valley.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.justify,
              ),
            ),
            _buildInstructionStep('1',
                'Pause your work and spend 15 mindful minutes outdoors to refresh your focus and lift your mood.'),
            _buildInstructionStep('2',
                'Download iNaturalist and join the WVG project to help ID organisms and photograph biodiversity.'),
            _buildInstructionStep('3',
                'Spend 10 minutes fully present with pollinators: observe, listen, and log your counts.'),
            const SizedBox(height: 24),
            _buildHeaderRow(),
            const Divider(thickness: 2),
            ..._pollinators
                .map((pollinator) => _buildPollinatorRow(pollinator)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text('Submit Observations'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
              radius: 12,
              backgroundColor: Colors.green,
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: [
        const Expanded(
            flex: 2,
            child: Text('Pollinator',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        Expanded(
            flex: 3,
            child: Text(_locations[0],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16))),
        Expanded(
            flex: 3,
            child: Text(_locations[1],
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16))),
      ],
    );
  }

  Widget _buildPollinatorRow(String pollinator) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(pollinator, style: const TextStyle(fontSize: 16))),
          Expanded(flex: 3, child: _buildCountBox(pollinator, _locations[0])),
          Expanded(flex: 3, child: _buildCountBox(pollinator, _locations[1])),
        ],
      ),
    );
  }

  Widget _buildCountBox(String pollinator, String location) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextFormField(
        controller: _controllers[pollinator]![location],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 10.0),
        ),
      ),
    );
  }
}
