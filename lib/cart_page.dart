import 'dart:io';

import 'package:electrition_bill/main.dart';
import 'package:electrition_bill/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CartScreen extends StatefulWidget {
  final List<Product> cart;
  final void Function(Product) removeFromCart;
  const CartScreen({super.key, required this.cart, required this.removeFromCart});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Map to track product quantities by product id
  final Map<int, int> productQuantities = {};

  @override
  Widget build(BuildContext context) {
    // Calculate total based on quantities
    double total = 0;
    for (final product in widget.cart) {
      final int id = int.tryParse(product.id.toString()) ?? 0;
      final qty = productQuantities[id] ?? 0;
      total += product.price * qty;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, size: 36), // Make cart icon bigger
                  onPressed: () {}, // Already on cart page, so do nothing
                ),
                if (widget.cart.isNotEmpty)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.all(2), // Smaller padding
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10), // Smaller radius
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          widget.cart.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
               ]
            )
          )
        ]
       ),
                
      body: widget.cart.isEmpty
          ? const Center(child: Text('Cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final product = widget.cart[index];
                      return ListTile(
                        leading: product.imageUrl.isNotEmpty && product.imageUrl.startsWith('http')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.image, size: 32, color: Colors.grey),
                        title: Text(product.name),
                        subtitle: Text('₹${product.price.toStringAsFixed(2)}',style: TextStyle(
                          fontSize: 15,
                          color: Colors.black
                        ),),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                setState(() {
                                  final int id = int.tryParse(product.id.toString()) ?? 0;
                                  final current = productQuantities[id] ?? 0;
                                  if (current > 0) productQuantities[id] = current - 1;
                                });
                              },
                            ),
                            Text('${productQuantities[int.tryParse(product.id.toString()) ?? 0] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.black)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() {
                                  final int id = int.tryParse(product.id.toString()) ?? 0;
                                  final current = productQuantities[id] ?? 0;
                                  productQuantities[id] = current + 1;
                                });
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 3.0),
                              child: Text(
                                '₹${((productQuantities[int.tryParse(product.id.toString()) ?? 0] ?? 0) * product.price).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Remove'),
                                    content: const Text('Are you sure you want to remove this product from the cart?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('No'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Yes'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  setState(() {
                                    widget.cart.removeAt(index);
                                    final int id = int.tryParse(product.id.toString()) ?? 0;
                                    productQuantities[id] = 0;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              
            
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        label: const Text('Download Bill'),
                        onPressed: () async {
                          // Calculate image width and height
                          const int width = 400;
                          final int rowHeight = 32;
                          final int headerHeight = 40;
                          final int footerHeight = 40;
                          final int tableRows = widget.cart.length + 1; // +1 for header
                          final int height = headerHeight + tableRows * rowHeight + footerHeight;

                          // Create image
                          final billImage = img.Image(width: width, height: height);
                          img.fill(billImage, color: img.ColorRgb8(255, 255, 255)); // White background

                          int y = 10;
                          img.drawString(billImage, 'Electrition Shop Bill', font: img.arial14, x: 10, y: y, color: img.ColorRgb8(0, 0, 0));
                          y += headerHeight;

                          // Draw table header
                          img.drawString(billImage, 'Product Name', font: img.arial14, x: 10, y: y, color: img.ColorRgb8(0, 0, 0));
                          img.drawString(billImage, 'Count', font: img.arial14, x: 180, y: y, color: img.ColorRgb8(0, 0, 0));
                          img.drawString(billImage, 'Price', font: img.arial14, x: 260, y: y, color: img.ColorRgb8(0, 0, 0));
                          y += rowHeight;

                          int totalCount = 0;
                          double totalPrice = 0;
                          for (final product in widget.cart) {
                            final int id = int.tryParse(product.id.toString()) ?? 0;
                            final count = productQuantities[id] ?? 0;
                            final price = product.price * count;
                            totalCount += count;
                            totalPrice += price;
                            img.drawString(billImage, product.name, font: img.arial14, x: 10, y: y, color: img.ColorRgb8(0, 0, 0));
                            img.drawString(billImage, count.toString(), font: img.arial14, x: 180, y: y, color: img.ColorRgb8(0, 0, 0));
                            img.drawString(billImage, '₹${price.toStringAsFixed(2)}', font: img.arial14, x: 260, y: y, color: img.ColorRgb8(0, 0, 0));
                            y += rowHeight;
                          }

                          // Draw footer row for totals
                          img.drawString(billImage, 'Total', font: img.arial14, x: 10, y: y, color: img.ColorRgb8(0, 0, 0));
                          img.drawString(billImage, totalCount.toString(), font: img.arial14, x: 180, y: y, color: img.ColorRgb8(0, 0, 0));
                          img.drawString(billImage, '₹${totalPrice.toStringAsFixed(2)}', font: img.arial14, x: 260, y: y, color: img.ColorRgb8(0, 0, 0));

                          // Save image to file
                          final directory = await getApplicationDocumentsDirectory();
                          final filePath = '${directory.path}/bill_${DateTime.now().millisecondsSinceEpoch}.png';
                          final file = File(filePath);
                          await file.writeAsBytes(img.encodePng(billImage));

                          // Save to gallery using gallery_saver
                          try {
                            await GallerySaver.saveImage(file.path);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bill downloaded to gallery!')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving bill: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ]     
          ),
            
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProfilePage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Add this to your _MyHomePageState


// In your GridView.builder itemBuilder, replace the Row with:
// (Paste this Row widget inside your widget tree where appropriate, not here at the file level)