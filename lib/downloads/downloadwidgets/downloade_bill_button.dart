

import 'package:flutter/material.dart';

import 'package:electrition_bill/downloads/download%20screen/downloade_page.dart';

class DownloadedBillsButton extends StatefulWidget {
  const DownloadedBillsButton({Key? key}) : super(key: key);

  @override
  State<DownloadedBillsButton> createState() => _DownloadedBillsButtonState();
}

class _DownloadedBillsButtonState extends State<DownloadedBillsButton> {

  bool _loading = false;


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton.icon(
          icon: const Icon(Icons.folder,color: Color.fromARGB(255, 219, 223, 11),size:30,),

          label: const Text('Show Downloaded Bills',style: TextStyle(
            color: Colors.black,
            fontSize: 20),),
          onPressed: _loading
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DownloadedBillsPage(),
                    ),
                  );
                },
        ),
       
      ],
    );
  }
}