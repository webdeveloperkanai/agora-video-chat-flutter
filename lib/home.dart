import 'package:flutter/material.dart';
import 'package:video_sdk_test/Call/Call.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController channel = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Join call"),
      ),
      body: ListView(
        padding: EdgeInsets.all(25),
        children: [
          Text("Enter call code"),
          TextFormField(controller: channel),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CallAttend(channelId: channel.text)));
              },
              child: Text("Attend Call"))
        ],
      ),
    );
  }
}
