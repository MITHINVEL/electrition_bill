import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:electrition_bill/core/constant.dart';
import 'package:electrition_bill/screens/edit_product_screen.dart';
import 'package:flutter/material.dart';
import 'package:electrition_bill/moels/product.dart';

class ProductStorePage extends StatefulWidget {
  final List<Product> cart;
  final void Function(Product, {int quantity}) addToCart;
  const ProductStorePage({super.key, required this.cart, required this.addToCart});

  @override
  State<ProductStorePage> createState() => _ProductStorePageState();
}

class _ProductStorePageState extends State<ProductStorePage> {
  Set<String> selectedProductIds = {};
  bool get isSelectionMode => selectedProductIds.isNotEmpty;

  List<Product> storedProducts = [];
  String searchQuery = '';

  StreamSubscription? _productSubscription;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _listenToProducts();
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _listenToProducts() {
    _productSubscription = FirebaseFirestore.instance.collection('products').snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          storedProducts = snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
        });
      }
    });
  }

  void _toggleSelection(String productId) {
    setState(() {
      if (selectedProductIds.contains(productId)) {
        selectedProductIds.remove(productId);
      } else {
        selectedProductIds.add(productId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedProductIds.clear();
    });
  }

  Future<void> _deleteSelectedProducts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Products'),
        content: const Text('Are you sure you want to delete the selected products?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No',style: TextStyle(color: Colors.black,
            fontSize: 20, fontWeight: FontWeight.w500, 
            fontFamily: 'Roboto'
            ),),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes',style: TextStyle(color: Colors.black,
            fontSize: 20, fontWeight: FontWeight.w500, 
            fontFamily: 'Roboto'
            ),),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // Ask for 4-digit password
      String? passwordResult = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final controller = TextEditingController();
          String? errorText;
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Enter 4-digit Password'),
                content: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                      fontFamily: 'Roboto',
                    ),
                    errorText: errorText,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: errorText != null ? Colors.red : primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: errorText != null ? Colors.red : primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20)
                    ),
                    focusedErrorBorder:OutlineInputBorder(
                      borderSide: BorderSide(
                        color: errorText != null ? Colors.red : primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20)
                    ) ,
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: errorText != null ? Colors.red : yellowColor,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(20)
                    ),
                  ),
                  style: TextStyle(
                    color: errorText != null ? Colors.red : Colors.black,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    fontSize: 24,
                  ),
                  onChanged: (val) {
                    setState(() {
                      errorText = null;
                    });
                  },
                  autofocus: true,
                  textAlign: TextAlign.center,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel',style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Roboto'
                    ),),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      if (controller.text == '7373') {
                        Navigator.of(context).pop(controller.text);
                      } else {
                        setState(() {
                          errorText = 'Password incorrect';
                        });
                      }
                    },
                    child: const Text('Confirm',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Roboto',),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
      if (passwordResult == '7373') {
        // Delete from Firestore and local list
        for (final id in selectedProductIds.toList()) {
          try {
            await FirebaseFirestore.instance.collection('products').doc(id).delete();
          } catch (e) {
            debugPrint('Failed to delete product $id: $e');
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected products deleted!')));
          _clearSelection();
        }
      } else if (passwordResult != null) {
        // Wrong password, show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password incorrect. Deletion cancelled.')));
        }
        _clearSelection();
      }
    } else {
      _clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = storedProducts.where((product) =>
      product.name.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
    // Unfocus search bar when tapping outside
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Product Store'),
          backgroundColor: primary,
          actions: [
            if (isSelectionMode) ...[
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red,size: 28,),
                    onPressed: _deleteSelectedProducts,
                  ),
                ],
              ),
            ],
            if (!isSelectionMode) ...[
              IconButton(
                icon: CircleAvatar(
                  radius: 29,
                  backgroundImage: const AssetImage('assets/images/logos/logo.jpg'),
                ),
                onPressed: () {},
              ),
            ],
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {},
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top:20, left: 12, right: 12, bottom: 8),
                child: TextField(
                  focusNode: _searchFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Search Product',
                    labelStyle: TextStyle(color: Colors.grey,
                    fontFamily: 'Roboto',
                      fontSize: 20),
                    prefixIcon: Icon(Icons.search),
                   enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primary,width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: yellowColor,width: 2),
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
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: selectedProductIds.length == filteredProducts.length && filteredProducts.isNotEmpty,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedProductIds = filteredProducts.map((p) => p.id).toSet();
                            } else {
                              selectedProductIds.clear();
                            }
                          });
                        },
                      ),
                      const Text('Select All'),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final isSelected = selectedProductIds.contains(product.id);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.withOpacity(0.08) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('₹${product.price.toStringAsFixed(2)}'),
                        selected: isSelected,
                        selectedTileColor: Colors.blue.withOpacity(0.1),
                        trailing: isSelectionMode
                            ? (isSelected
                                ? const Icon(Icons.check_circle, color: Colors.blue)
                                : const Icon(Icons.radio_button_unchecked, color: Colors.grey))
                            : null,
                        onLongPress: () => _toggleSelection(product.id),
                        onTap: isSelectionMode
                            ? () => _toggleSelection(product.id)
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EditProductScreen(product: product),
                                  ),
                                );
                              },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
