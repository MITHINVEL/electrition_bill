import 'package:electrition_bill/moels/product.dart';

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
                    return ListTile(
                      title: Text(productName),
                      subtitle: Text('₹${productPrice.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          int count = 1;
                          showDialog(
                            context: context,
                            builder: (context) {
                              return StatefulBuilder(
                                builder: (context, setStateDialog) {
                                  return AlertDialog(
                                    title: Text(productName),
                                    content: Row(
                                      children: [
                                        const Text('Count: '),
                                        Expanded(
                                          child: TextField(
                                            autofocus: true,
                                            keyboardType: TextInputType.number,
                                            onChanged: (val) {
                                              final parsed = int.tryParse(val);
                                              if (parsed != null && parsed > 0) {
                                                setStateDialog(() { count = parsed; });
                                              }
                                            },
                                            decoration: InputDecoration(
                                              hintText: count.toString(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Add to cart logic here (you can use Provider, setState, or any state management)
                                          // For demo, show a SnackBar with total price
                                          final total = productPrice * count;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('$productName x$count added. Total: ₹${total.toStringAsFixed(2)}')),
                                          );
                                          final product = Product(
                                            id: products[index].id,
                                            name: productName,
                                            price: productPrice,
                                            // Add other fields if needed
                                          );
                                          widget.addToCart(product, quantity: count);
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
