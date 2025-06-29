import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCountButton extends StatefulWidget {
  const ProductCountButton({Key? key}) : super(key: key);

  @override
  State<ProductCountButton> createState() => _ProductCountButtonState();
}

class _ProductCountButtonState extends State<ProductCountButton> {
  Stream<QuerySnapshot>? _productStream;

  @override
  void initState() {
    super.initState();
    _productStream = FirebaseFirestore.instance.collection('products').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _productStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.inventory, color: Colors.deepPurple),
            label: const Text('Loading...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.deepPurple.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }
        final count = snapshot.data?.docs.length ?? 0;
        return TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.inventory, color: Colors.deepPurple),
          label: Text(
            'Total Products: $count',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.deepPurple.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      },
    );
  }
}
