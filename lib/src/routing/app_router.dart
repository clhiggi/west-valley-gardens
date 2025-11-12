import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/screens/home_page.dart';
import 'package:myapp/screens/events_page.dart';
import 'package:myapp/screens/flyers_page.dart';
import 'package:myapp/screens/meetings_page.dart';
import 'package:myapp/screens/pause_page.dart';
import 'package:myapp/screens/problems_page.dart';
import 'package:myapp/widgets/scaffold_with_nav_bar.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // Instances for dependency injection
  static final _firestore = FirebaseFirestore.instance;
  static final _imagePicker = ImagePicker();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch for the Home page
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (BuildContext context, GoRouterState state) => const HomePage(),
              ),
            ],
          ),

          // Branch for the Events page and its nested routes
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (BuildContext context, GoRouterState state) {
                  return EventsPage(
                    firestore: _firestore,
                    imagePicker: _imagePicker,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'flyers',
                    builder: (BuildContext context, GoRouterState state) {
                      final event = state.extra as Event?;
                      if (event == null) {
                        return Scaffold(
                          appBar: AppBar(title: const Text('Error')),
                          body: const Center(child: Text('No event details provided.')),
                        );
                      }
                      return FlyersPage(
                        event: event,
                        firestore: _firestore,
                        imagePicker: _imagePicker,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch for the Meetings page
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/meetings',
                builder: (BuildContext context, GoRouterState state) => const MeetingsPage(),
              ),
            ],
          ),

          // Branch for the Pause page
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pause',
                builder: (BuildContext context, GoRouterState state) => const PausePage(),
              ),
            ],
          ),

          // Branch for the Problems page
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/problems',
                builder: (BuildContext context, GoRouterState state) => const ProblemsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error?.message ?? 'Unknown error'}'),
      ),
    ),
  );
}
