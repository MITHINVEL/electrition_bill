import 'package:electrition_bill/contents/assets.dart';
import 'package:electrition_bill/core/constant.dart';
import 'package:electrition_bill/downloads/downloadwidgets/downloade_bill_button.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('Profile',
         style: TextStyle(color: white,
         fontSize: 32,
       fontFamily: 'Roboto',

         )),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundImage: AssetImage('assets/images/logos/logo.jpg'),
            ),
            const SizedBox(height: 16),
            const Text('DURGA ELECTRICALS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('user@email.com', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            const Text('Profile details and settings will appear here.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            const DownloadedBillsButton(),
          ],
        ),
      ),
    );
  }
}

