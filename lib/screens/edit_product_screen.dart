import 'package:electrition_bill/core/constant.dart';
import 'package:electrition_bill/moels/product.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(text: widget.product.price.toString());
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void _updateProduct() async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text.trim()) ?? 0.0;
    // Ask for 4-digit password before update
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
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: errorText != null ? Colors.red : const Color.fromARGB(255, 216, 213, 183),
                      width: 2,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(20.0)
                  ),),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: errorText != null ? Colors.red : yellowColor,
                      width: 2,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: errorText != null ? Colors.red : primary,
                      width: 2,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: errorText != null ? Colors.red : yellowColor,
                      width: 2.5,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(20.0)),
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
                  child: const Text('Cancel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: black,
                    fontFamily: 'Roboto',
                  ),
                  ),
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
                    color: black,
                    fontFamily: 'Roboto',
                  ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (passwordResult == '7373') {
      setState(() { isLoading = true; });
      try {
        await FirebaseFirestore.instance.collection('products').doc(widget.product.id).update({
          'name': name,
          'price': price,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated!')));
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('Update product error: $e');
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to update product: $e'),
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
    } else if (passwordResult != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password incorrect. Update cancelled.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: const Text('Edit Product',
      style: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w500,
      ),),
      backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔌 Update Your Item',
              style: TextStyle(
                fontSize: 30,
                color: black,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
              )
              ),
              
            const SizedBox(height: 50),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product Name',
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
            ),
            SizedBox(height: 35),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price',
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
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _updateProduct,
                          child: const Text('Update',style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: black
                                ),),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(214, 244, 67, 54)),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Product',style: TextStyle(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w500,
                                  color: black
                                ),),
                                content: const Text('Are you sure you want to delete this product?',
                                style: TextStyle(
                                  fontSize: 20,
                                 
                                  color: black
                                ),),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel',style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w500,
                                  color: Color.fromARGB(255, 56, 139, 187)
                                ),),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('OK',style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: black
                                ),),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              // Ask for 4-digit password before delete
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
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: errorText != null ? Colors.red : const Color.fromARGB(255, 216, 213, 183),
                                                width: 2,
                                              ),
                                              borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                                            ),
                                            focusedErrorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: errorText != null ? Colors.red : yellowColor,
                                                width: 2,
                                              ),
                                              borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                                            ),
                                            border: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: errorText != null ? Colors.red : primary,
                                                width: 2,
                                              ),
                                              borderRadius: const BorderRadius.all(Radius.circular(20.0)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: errorText != null ? Colors.red : yellowColor,
                                                width: 2.5,
                                              ),
                                              borderRadius: const BorderRadius.all(Radius.circular(20.0)),
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
                                            child: const Text('Cancel',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                              color: black,
                                              fontFamily: 'Roboto',),
                                            ),
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
                                              color: black,
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
                                setState(() { isLoading = true; });
                                await FirebaseFirestore.instance.collection('products').doc(widget.product.id).delete();
                                setState(() { isLoading = false; });
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Product deleted!')),
                                  );
                                  Navigator.of(context).pop();
                                }
                              } else if (passwordResult != null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Password incorrect. Deletion cancelled.')),
                                  );
                                }
                              }
                            }
                          },
                          child: const Text('Delete',style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  color: black
                                ),),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
