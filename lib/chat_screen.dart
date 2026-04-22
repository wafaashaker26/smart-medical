import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<String> messages = [];
  TextEditingController controller = TextEditingController();

  void sendMessage() {
    setState(() {
      messages.add("User: ${controller.text}");

      // هنا هتربطي Gemini API لاحقًا
      messages.add("AI: I am analyzing your symptoms...");
    });

    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Doctor Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: messages.map((m) => Text(m)).toList(),
            ),
          ),

          TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Your answer"),
          ),

          ElevatedButton(
            onPressed: sendMessage,
            child: Text("Send"),
          )
        ],
      ),
    );
  }
}