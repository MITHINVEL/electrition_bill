import 'dart:ui';

import 'package:electrition_bill/main.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final void Function(Product) addToCart;
  const ProductDetailPage({super.key, required this.product, required this.addToCart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final nameController = TextEditingController(text: product.name);
                                final priceController = TextEditingController(text: product.price.toString());
                                final imageUrlController = TextEditingController(text: product.imageUrl);
                                final result = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Edit Product'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextField(
                                          controller: nameController,
                                          decoration: const InputDecoration(labelText: 'Product Name'),
                                        ),
                                        TextField(
                                          controller: priceController,
                                          decoration: const InputDecoration(labelText: 'Price'),
                                          keyboardType: TextInputType.number,
                                        ),
                                        TextField(
                                          controller: imageUrlController,
                                          decoration: const InputDecoration(labelText: 'Image URL'),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                );
                                if (result == true) {
                                  final updatedProduct = Product(
                                    id: product.id,
                                    name: nameController.text,
                                    price: double.tryParse(priceController.text) ?? 0.0,
                                    imageUrl: imageUrlController.text,
                                  );
                                  // Update the product in Firestore
                                  await FirebaseFirestore.instance.collection('products').doc(product.id).update({
                                    'name': updatedProduct.name,
                                    'price': updatedProduct.price,
                                    'imageUrl': updatedProduct.imageUrl,
                                  });
                                  // Optionally, you can also update the local state or notify listeners
                                  addToCart(updatedProduct);
                                }
                              },
                            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Center(
                child: product.imageUrl.startsWith('http')
                    ? Image.network(product.imageUrl, fit: BoxFit.contain, width: double.infinity, height: double.infinity)
                    : const Icon(Icons.broken_image, size: 120, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('₹${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, color: Colors.green)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => addToCart(product),
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Node.js backend integration example (for demonstration)
// You can use http package to call your Node.js backend API from Flutter
// Example:
// import 'package:http/http.dart' as http;
// Future<void> callNodeApi() async {
//   final response = await http.get(Uri.parse('http://your-node-server/api/endpoint'));
//   if (response.statusCode == 200) {
//     // Handle response
//   }
// }

// Example function to call Node.js backend
Future<void> callNodeApi() async {
  try {
    final response = await http.get(Uri.parse('http://localhost:3000/api/endpoint'));
    if (response.statusCode == 200) {
      // You can parse the response here
      print('Node.js response: ' + response.body);
      // Optionally show a snackbar or update UI
    } else {
      print('Node.js error: ${response.statusCode}');
    }
  } catch (e) {
    print('Node.js connection error: $e');
  }
}
