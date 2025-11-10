import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:myapp/src/constants/theme.dart';
import 'package:myapp/src/routing/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'West Valley Gardens',
      theme: lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}

