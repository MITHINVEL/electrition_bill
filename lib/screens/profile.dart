
import 'package:electrition_bill/core/constant.dart';
import 'package:electrition_bill/downloads/downloadwidgets/downloade_bill_button.dart';
import 'package:flutter/material.dart';

import '../../widgets/product_count_button.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: const Text('DURGA  ELECTRICALS',
         style: TextStyle(color:black,
         fontSize: 23,
         fontWeight: FontWeight.w500,
       fontFamily: 'Roboto',

         )),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/images/logos/logo.jpg'),
            ),
            const SizedBox(height: 16),
            const Text('DURGA ELECTRICALS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Address row
            const Text('Pennagaram Main Road, B Agraharam',
                style: TextStyle(fontSize: 16, color: Colors.black54, fontFamily: 'Roboto', fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            const Text('Cell: 7373478899, 9787677881',
                style: TextStyle(fontSize: 16, color: Colors.black54, fontFamily: 'Roboto', fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            // Product count row
            ProductCountButton(),
            const SizedBox(height: 32),
            const DownloadedBillsButton(),
          ],
        ),
      ),
     
    );
  }
}

