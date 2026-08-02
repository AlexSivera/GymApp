import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GymApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
