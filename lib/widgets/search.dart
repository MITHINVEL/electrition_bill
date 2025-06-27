import 'package:electrition_bill/moels/product.dart';
import 'package:electrition_bill/widgets/percentage_screen.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchPage extends StatefulWidget {
  final List<Product> cart;
  final void Function(Product, {int quantity}) addToCart;

  const SearchPage({super.key, required this.cart, required this.addToCart});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String searchQuery = '';
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  // --- New logic for staged cart and percentage screen ---
  // Move stagedCart, stagedQuantities, stagedPercentages to class-level fields
  // so they persist across rebuilds
  List<Product> stagedCart = [];
  Map<String, int> stagedQuantities = {};
  Map<String, double> stagedPercentages = {};

  @override
  void initState() {
    super.initState();
    // Request focus when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              focusNode: _searchFocus,
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name']?.toString().toLowerCase() ?? '';
                  return name.contains(searchQuery.toLowerCase());
                }).toList();
                if (products.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final data = products[index].data() as Map<String, dynamic>;
                    final productName = data['name'] ?? '';
                    final productPrice = (data['price'] as num?)?.toDouble() ?? 0.0;
                    final productId = products[index].id;
                    return ListTile(
                      title: Text(productName),
                      subtitle: Text('₹${productPrice.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () async {
                          final result = await showDialog<int>(
                            context: context,
                            builder: (context) {
                              final controller = TextEditingController(text: '1');
                              return AlertDialog(
                                title: Text(productName),
                                content: TextField(
                                  autofocus: true,
                                  keyboardType: TextInputType.number,
                                  controller: controller,
                                  decoration: const InputDecoration(labelText: 'Count'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final val = int.tryParse(controller.text);
                                      if (val != null && val > 0) {
                                        Navigator.of(context).pop(val);
                                      }
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (result != null && result > 0) {
                            // Add to staged cart
                            final prod = Product(id: productId, name: productName, price: productPrice);
                            for (int i = 0; i < result; i++) {
                              stagedCart.add(prod);
                            }
                            stagedQuantities[productId] = (stagedQuantities[productId] ?? 0) + result;
                            stagedPercentages[productId] = 0.0;
                            // Show SnackBar at the top
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$productName x$result staged. Tap "Go to Percentage" below.'),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
                // --- End new logic ---
              },
            ),
          ),
          // New button to go to PercentageScreen
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (stagedCart.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add at least one product.')),
                    );
                    return;
                  }
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PercentageScreen(
                        products: stagedCart.toSet().toList(),
                        initialQuantities: stagedQuantities,
                        initialPercentages: stagedPercentages,
                      ),
                    ),
                  );
                  if (result != null && result is List<Product> && result.isNotEmpty) {
                    // Go to bill page with selected products
                    widget.addToCart(result.first, quantity: 1); // You may want to refactor this for your bill page
                  }
                },
                child: const Text('Go to Percentage'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
