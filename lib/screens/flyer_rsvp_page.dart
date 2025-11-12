import 'package:flutter/material.dart';

class FlyerRsvpPage extends StatelessWidget {
  final String flyerPath;
  final String eventId;

  const FlyerRsvpPage({
    super.key,
    required this.flyerPath,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Flyer')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: flyerPath.isNotEmpty
                  ? Image.network(
                      flyerPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'Unable to load flyer image.',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    )
                  : const Text(
                      'No flyer available.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.event_available),
              label: const Text('RSVP'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('RSVP successful!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
