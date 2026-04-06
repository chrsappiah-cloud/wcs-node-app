import 'package:flutter/material.dart';

import 'wcs_profile_screen.dart';
import 'wcs_theme.dart';

void main() {
  runApp(const WcsApp());
}

class WcsApp extends StatelessWidget {
  const WcsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WCS Flutter Demo',
      theme: WcsTheme.dark(),
      home: const WcsProfileScreen(),
    );
  }
}
