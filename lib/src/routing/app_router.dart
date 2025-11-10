import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/screens/biodiversity_page.dart';
import 'package:myapp/screens/events_page.dart';
import 'package:myapp/screens/home_page.dart';
import 'package:myapp/screens/meetings_page.dart';
import 'package:myapp/screens/pause_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) {
          return NoTransitionPage(
            child: Scaffold(
              body: navigationShell,
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: navigationShell.currentIndex,
                onTap: (index) => navigationShell.goBranch(index),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.event), label: 'Events'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.group), label: 'Meetings'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.pause), label: 'Pause'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.bar_chart), label: 'Biodiversity'),
                ],
              ),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) => const EventsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meetings',
                builder: (context, state) => const MeetingsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pause',
                builder: (context, state) => const PausePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/biodiversity',
                builder: (context, state) => const BiodiversityPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
