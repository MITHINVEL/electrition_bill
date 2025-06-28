import 'package:electrition_bill/core/constant.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    _nameFocusNode.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  void _addProduct() async {
    final name = nameController.text.trim();
    final price = priceController.text.trim();
    if (name.isNotEmpty && double.tryParse(price) != null) {
      setState(() { isLoading = true; });
      try {
        // Check for duplicate name (case-insensitive, full match)
        final existing = await FirebaseFirestore.instance
            .collection('products')
            .where('name', isEqualTo: name)
            .get();
        if (existing.docs.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Already added!')),
            );
            priceController.clear();
          }
        } else {
          // Add to Firestore
          await FirebaseFirestore.instance.collection('products').add({
            'name': name,
            'price': double.parse(price),
          });
          if (mounted) {
            nameController.clear();
            priceController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Product added successfully!')),
            );
          }
        }
      } catch (e, stack) {
        debugPrint('Add product error: $e\n$stack');
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to add product: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() { isLoading = false; });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid name and price.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap Scaffold with GestureDetector to unfocus input when tapping outside
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Product'),
          backgroundColor: primary,
          actions: [
            IconButton(
                icon: CircleAvatar(
                  radius: 29,
                  backgroundImage: const AssetImage('assets/images/logos/logo.jpg'),
                ),
                onPressed: () {},
              ),
            
          ],
        
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🔌 Add New Item',
              style: TextStyle(
                fontSize: 30,
                color: black,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
              )
              ),
              SizedBox(height: 40),
              TextField(
                focusNode: _nameFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Roboto',
                    fontSize: 20,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primary,width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: yellowColor,width: 2.5),
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  ),
                ),
                controller: nameController,
              ),
              SizedBox(height: 25),
              TextField(
                focusNode: _priceFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  labelStyle: TextStyle(
                    color: Colors.grey,
                    fontFamily: 'Roboto',
                    fontSize: 20,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primary,width: 2),
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: yellowColor,width: 2.5),
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  ),
                ),
                keyboardType: TextInputType.number,
                controller: priceController,
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : Container(
                    width: 250,
                    
                    child: ElevatedButton(
                        onPressed: _addProduct,
                        child: Padding(
                    padding: const EdgeInsets.only(left:60),
                    child: Row(
                      children: [
                        
                        const Text('ADD',style: TextStyle(
                          color: black,
                          fontSize: 25
                        ),),
                        SizedBox(width: 10),
                      const Icon(Icons.arrow_upward,
                       color: blue ,
                       size: 35,)
                      ],
                    ),
                  ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

