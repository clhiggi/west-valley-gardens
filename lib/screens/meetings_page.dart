import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MeetingsPage extends StatelessWidget {
  const MeetingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meetings')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMeetingSection(
                context,
                title: 'Weekly Student Leadership Meetings',
                description:
                    'Weekly student leader meetings are essential for consistent collaboration and communication, allowing leaders to share ideas, address student needs promptly, and coordinate activities that strengthen engagement, leadership skills, and a positive school community.',
                zoomLink:
                    'https://asu.zoom.us/j/88159476872?pwd=XHEOag6FkA0DVjusTQg5VijoqifgtF.1',
                previousMeetingsLink:
                    'https://drive.google.com/drive/folders/1_CraqKb0mrxg8a0-lGCMiYlSitt5hY41?usp=drive_link',
              ),
              const SizedBox(height: 32),
              _buildMeetingSection(
                context,
                title:
                    'Monthly Faculty, Staff, and Community Supporters Meetings',
                description:
                    'Monthly meetings with faculty, staff, and community supporters are essential for collaboration and open communication, helping align goals, share updates, and strengthen partnerships that support student success and a positive school environment.',
                zoomLink:
                    'https://asu.zoom.us/j/89617088420?pwd=NVbGQAY0iaIuC7QSHpxeqRboAfGUbO.1',
                previousMeetingsLink:
                    'https://drive.google.com/drive/folders/1_CraqKb0mrxg8a0-lGCMiYlSitt5hY41?usp=drive_link',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingSection(
    BuildContext context, {
    required String title,
    String? description,
    required String zoomLink,
    required String previousMeetingsLink,
  }) {
    const TextStyle bodyTextStyle = TextStyle(fontSize: 16.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (description != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Text(description, style: bodyTextStyle),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _launchURL(zoomLink),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8E6C9),
              ),
              child: const Text(
                'Join Live Zoom Meeting',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _launchURL(previousMeetingsLink),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8E6C9),
              ),
              child: const Text(
                'Watch Previous Meetings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }
}
