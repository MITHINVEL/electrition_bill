import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore, QuerySnapshot;
import 'package:electrition_bill/moels/product.dart';
import 'package:electrition_bill/screens/billscreen.dart';
import 'package:electrition_bill/screens/edit_product_screen.dart';
import 'package:electrition_bill/widgets/search.dart';
import 'package:flutter/material.dart';

class ProductListPage extends StatefulWidget {
  final List<Product> cart;
  final void Function(Product, {int quantity}) addToCart;
  const ProductListPage({super.key, required this.cart, required this.addToCart});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  Set<String> selectedProductIds = {};
  bool get isSelectionMode => selectedProductIds.isNotEmpty;

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
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      for (final id in selectedProductIds.toList()) {
        await FirebaseFirestore.instance.collection('products').doc(id).delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected products deleted!')));
      _clearSelection();
    } else {
      _clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electrition Shop Bill'),
        backgroundColor: Colors.purple,
        actions: [
          
          if (isSelectionMode) ...[
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteSelectedProducts,
                ),
              ],
            ),
          ],
          if (!isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SearchPage(cart: widget.cart, addToCart: widget.addToCart),
                  ),
                );
              },
            ),
            IconButton(
              icon: CircleAvatar(
                radius: 29,
                backgroundImage: const AssetImage('assets/logos/logo.jpg'),
              ),
              onPressed: () {},
            ),
          ],
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!.docs.map((doc) => Product.fromDoc(doc)).toList();
          return Column(
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Checkbox(
                        value: selectedProductIds.length == products.length && products.isNotEmpty,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedProductIds = products.map((p) => p.id).toSet();
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
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isSelected = selectedProductIds.contains(product.id);
                    return ListTile(
                      title: Text(product.name),
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
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
