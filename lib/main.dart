import 'package:flutter/material.dart';
import 'routes.dart';

void main() {
  runApp(Face2FaceApp());
}

class Face2FaceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face2Face',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/login',
      routes: appRoutes,
    );
  }
}
