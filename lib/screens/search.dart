import 'package:electrition_bill/core/constant.dart';
import 'package:electrition_bill/moels/product.dart';
import 'package:electrition_bill/screens/percentage_screen.dart';

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
    return GestureDetector( 
       onTap: () {
      FocusScope.of(context).unfocus();
    },
    child: Scaffold(
      appBar: AppBar(
         backgroundColor: primary,
        title: const Text('Search Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              autofocus: true,
              focusNode: _searchFocus,
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                labelStyle: TextStyle(
                  fontSize: 25
                ),
                prefixIcon: Icon(Icons.search),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primary,width: 2),
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: yellowColor,width: 2.5),
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                 
                ),
                
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(productName),
                          subtitle: Text('₹${productPrice.toStringAsFixed(2)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add,
                            size: 30,
                            color: blue, // Changed to blue for consistency
                            ),
                            onPressed: () async {
                              int initialCount = stagedQuantities[productId] ?? 1;
                              final result = await showDialog<int>(
                                context: context,
                                builder: (context) {
                                  final controller = TextEditingController(
                                    text: initialCount.toString()
                                  );
                                  // Automatically select all text so typing replaces it
                                  controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
                                  return AlertDialog(
                                    title: Text(productName),
                                    content: TextField(
                                      autofocus: true,
                                      keyboardType: TextInputType.number,
                                      controller: controller,
                                      decoration: const InputDecoration(labelText: 'Count',
                                      labelStyle: TextStyle(
                                fontSize: 25
                                       ),
                                  prefixIcon: Icon(Icons.search),
                                          enabledBorder: OutlineInputBorder(
                                   borderSide: BorderSide(color: primary,width: 2),
                                     borderRadius: BorderRadius.all(Radius.circular(20.0)),
                                ),
                                    focusedBorder: OutlineInputBorder(
                                       borderSide: BorderSide(color: yellowColor,width: 2.5),
                                     borderRadius: BorderRadius.all(Radius.circular(20.0)),
                          
                ),
                                      ),
                                      onChanged: (val) {
                                        controller.value = controller.value.copyWith(
                                          text: val,
                                          selection: TextSelection.collapsed(offset: val.length),
                                        );
                                      },
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel',style: TextStyle(
                                          color: black,
                                          fontFamily: 'Roboto',
                                          fontSize: 20
                                        ),),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          final val = int.tryParse(controller.text);
                                          if (val != null && val > 0) {
                                            Navigator.of(context).pop(val);
                                          }
                                        },
                                        child: const Text('OK',style: TextStyle(
                                          color: black,
                                          fontFamily: 'Roboto',
                                          fontSize: 20
                                        ),),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (result != null && result > 0) {
                                // Remove all previous of this product from stagedCart
                                stagedCart.removeWhere((p) => p.id == productId);
                                // Add the new count
                                final prod = Product(id: productId, name: productName, price: productPrice);
                                for (int i = 0; i < result; i++) {
                                  stagedCart.add(prod);
                                }
                                stagedQuantities[productId] = result;
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
                        ),
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
            padding: const EdgeInsets.only(left: 20.0,bottom: 20,top: 10),
            child: SizedBox(
              
              width: 250,
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
                
                child: Padding(
                  padding: const EdgeInsets.only(left:5.0),
                  child: Row(
                    children: [
                      const Text('Go to Percentage',style: TextStyle(
                        color: black,
                        fontSize: 19
                      ),),
                      IconButton(onPressed: () {},
                       icon: const Icon(Icons.arrow_forward,
                       color: blue ,
                       size: 25,))
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
