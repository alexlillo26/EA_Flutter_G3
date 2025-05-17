import 'package:flutter/material.dart';

class GymHomeScreen extends StatelessWidget {
  const GymHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Gimnasio'),
        backgroundColor: Colors.black,
      ),
      body: const Center(
        child: Text(
          'Bienvenido al panel de tu gimnasio',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
    );
  }
}