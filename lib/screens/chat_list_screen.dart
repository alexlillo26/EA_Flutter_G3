import 'package:flutter/material.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.red,
      ),
      body: const Center(
        child: Text(
          'Lista de chats',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}