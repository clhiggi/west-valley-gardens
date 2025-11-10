import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('West Valley Gardens'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '“The West Valley Gardens is a place of healing and community for West Valley students — feeding them when they can’t afford their meal plan, caring for them when they can’t get mental health support, and offering them accessible internship-level research and advocacy experience when they can’t travel outside of their campus or need a place that just feels like home. We strive to advance native biodiversity and Indigenous rights and cultures, as well as contribute to social justice, sustainability, and climate action. It has been an honor to provide this resource to the West Valley community — so undergraduates and graduate students, faculty, staff, and community members alike can begin to rekindle an appreciation to our land again.”\n\n– Lindsey Stevens',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _launchURL(
                  'https://newcollege.asu.edu/west-valley-gardens',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[100],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Visit our Website'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _launchURL(
                  'https://www.instagram.com/westvalleygardens/',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[100],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Follow us on Instagram'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
