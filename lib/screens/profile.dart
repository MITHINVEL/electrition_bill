import 'package:electrition_bill/downloads/downloadwidgets/downloade_bill_button.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircleAvatar(
              radius: 48,
              child: Icon(Icons.person, size: 48),
            ),
            SizedBox(height: 16),
            Text('User Name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('user@email.com', style: TextStyle(fontSize: 16)),
            SizedBox(height: 32),
            Text('Profile details and settings will appear here.', style: TextStyle(fontSize: 16)),
            SizedBox(height: 32),
            DownloadedBillsButton(),
          ],
        ),
      ),
    );
  }
}

