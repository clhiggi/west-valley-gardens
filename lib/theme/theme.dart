// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/theme/colors.dart';

class ViewDataPage extends StatelessWidget {
  const ViewDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> westValleyGardensData = {
      'Bees': 0.30,
      'Beetles': 0.15,
      'Butterflies': 0.20,
      'Flies': 0.10,
      'Moths': 0.15,
      'Wasps': 0.10,
    };

    final Map<String, double> westValleyCampusData = {
      'Bees': 0.40,
      'Beetles': 0.10,
      'Butterflies': 0.25,
      'Flies': 0.05,
      'Moths': 0.10,
      'Wasps': 0.10,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pollinator Data',
          style: GoogleFonts.oswald(
            color: asuMaroon,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: asuMaroon),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDataChart(
                context, 'West Valley Gardens', westValleyGardensData),
            const SizedBox(height: 40),
            _buildDataChart(
                context, 'West Valley Campus', westValleyCampusData),
          ],
        ),
      ),
    );
  }

  Widget _buildDataChart(
      BuildContext context, String title, Map<String, double> data) {
    if (data.isEmpty) {
      return Card(
        color: asuGold.withOpacity(0.1),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No data available for this location',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Build simple custom bar chart using Rows and Containers
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: asuGold,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: GoogleFonts.oswald(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: asuMaroon,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Column(
              children: data.entries.map((entry) {
                final percentage = (entry.value * 100).toStringAsFixed(0);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          entry.key,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: richBlack,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: entry.value,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  color: asuMaroon,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$percentage%',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          color: richBlack,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Relative abundance of pollinator types',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                color: richBlack,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
