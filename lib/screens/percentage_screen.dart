import 'package:electrition_bill/core/constant.dart';
import 'package:flutter/material.dart';
import 'package:electrition_bill/moels/product.dart';
import 'package:electrition_bill/screens/billscreen.dart';
import 'package:collection/collection.dart';

class PercentageScreen extends StatefulWidget {
  final List<Product> products;
  final Map<String, int> initialQuantities;
  final Map<String, double> initialPercentages;

  const PercentageScreen({
    super.key,
    required this.products,
    required this.initialQuantities,
    required this.initialPercentages,
  });

  @override
  State<PercentageScreen> createState() => _PercentageScreenState();
}

class _PercentageScreenState extends State<PercentageScreen> {
  late List<bool> selectedIndices;
  late Map<String, int> quantities;
  late Map<String, double> percentages;
  late Map<String, double> discountedPrices;
  bool selectionMode = false;

  @override
  void initState() {
    super.initState();
    selectedIndices = List<bool>.filled(widget.products.length, false).toList(); // Make growable
    quantities = Map<String, int>.from(widget.initialQuantities);
    percentages = Map<String, double>.from(widget.initialPercentages);
    discountedPrices = {
      for (var p in widget.products)
        p.id: _calculateDiscountedPrice(p.price, percentages[p.id] ?? 0)
    };
  }

  double _calculateDiscountedPrice(double price, double percent) {
    return price + (price * percent / 100);
  }

  void _editProduct(String productId) async {
    final currentQty = quantities[productId] ?? 1;
    final currentPercent = percentages[productId] ?? 0.0;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        final qtyController = TextEditingController(text: currentQty.toString());
        final percentController = TextEditingController(text: currentPercent.toStringAsFixed(2));
        return AlertDialog(
          title: const Text('Edit Quantity & Percentage'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity',
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
                 
                ),),
                onChanged: (_) {
                  setState(() {}); // force rebuild for total update
                },
              ),
              const SizedBox(height: 22),
              TextField(
                controller: percentController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Percentage %',
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
                 
                ),),
                onChanged: (_) {
                  setState(() {}); // force rebuild for total update
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                style: TextStyle(
                  fontSize: 20,
                  color: black,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyController.text);
                final percent = double.tryParse(percentController.text);
                if (qty != null && qty > 0 && percent != null && percent >= 0 && percent <= 100) {
                  Navigator.of(context).pop({'qty': qty, 'percent': percent});
                }
              },
              child: const Text('OK',
                style: TextStyle(
                  fontSize: 20,
                  color: black,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        quantities[productId] = result['qty'];
        percentages[productId] = result['percent'];
        final product = widget.products.firstWhere((p) => p.id == productId);
        discountedPrices[productId] = _calculateDiscountedPrice(product.price, result['percent']);
      });
    }
  }

  void _syncSelectedIndices() {
    if (selectedIndices.length != widget.products.length) {
      final diff = widget.products.length - selectedIndices.length;
      if (diff > 0) {
        selectedIndices.addAll(List<bool>.filled(diff, false));
      } else if (diff < 0) {
        selectedIndices = selectedIndices.sublist(0, widget.products.length);
      }
    }
  }

  double _calculateTotal() {
    double total = 0.0;
    for (int i = 0; i < widget.products.length; i++) {
      if (selectedIndices[i]) {
        final p = widget.products[i];
        final qty = quantities[p.id] ?? 1;
        final percent = percentages[p.id] ?? 0.0;
        final price = _calculateDiscountedPrice(p.price, percent);
        total += price * qty;
      }
    }
    return total;
  }

  double _calculateGrandTotal() {
    double total = 0.0;
    for (var p in widget.products) {
      final qty = quantities[p.id] ?? 1;
      final percent = percentages[p.id] ?? 0.0;
      final price = _calculateDiscountedPrice(p.price, percent);
      total += price * qty;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    _syncSelectedIndices();
    final selectedCount = selectedIndices.where((v) => v).length;
    return Scaffold(
      appBar: selectionMode
          ? AppBar(
              title: Text('$selectedCount Selected'),
              leading: IconButton(
                icon: const Icon(Icons.select_all),
                tooltip: 'Select All',
                onPressed: () {
                  setState(() {
                    final allSelected = quantities.keys.every((productId) {
                      final idx = widget.products.indexWhere((p) => p.id == productId);
                      return idx != -1 && selectedIndices[idx];
                    });
                    for (final productId in quantities.keys) {
                      final idx = widget.products.indexWhere((p) => p.id == productId);
                      if (idx != -1) {
                        selectedIndices[idx] = !allSelected;
                      }
                    }
                  });
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Selected',
                  onPressed: selectedCount == 0
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Selected Products'),
                              content: const Text('Are you sure you want to delete the selected products?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('No',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: black,
                                      fontFamily: 'Roboto',
                                  )),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Yes',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: black,
                                      fontFamily: 'Roboto',
                                  )),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            setState(() {
                              for (int i = selectedIndices.length - 1; i >= 0; i--) {
                                if (selectedIndices[i]) {
                                  final productId = widget.products[i].id;
                                  widget.products.removeAt(i);
                                  selectedIndices.removeAt(i);
                                  quantities.remove(productId);
                                  percentages.remove(productId);
                                  discountedPrices.remove(productId);
                                }
                              }
                              _syncSelectedIndices();
                              selectionMode = false;
                            });
                          }
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Selected',
                  onPressed: selectedCount == 0
                      ? null
                      : () async {
                          final percentController = TextEditingController();
                          final result = await showDialog<double>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Set Discount % for Selected'),
                                content: TextField(
                                  autofocus: true,
                                  controller: percentController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'percentage %',
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
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: black,
                                        fontFamily: 'Roboto',
                                      ),)
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final percent = double.tryParse(percentController.text);
                                      if (percent != null && percent >= 0 && percent <= 100) {
                                        Navigator.of(context).pop(percent);
                                      }
                                    },
                                    child: const Text('OK',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: black,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                          if (result != null) {
                            setState(() {
                              for (int i = 0; i < widget.products.length; i++) {
                                if (selectedIndices[i]) {
                                  final p = widget.products[i];
                                  percentages[p.id] = result;
                                  discountedPrices[p.id] = _calculateDiscountedPrice(p.price, result);
                                }
                              }
                            });
                          }
                        },
                ),
              ],
            )
          : AppBar(
              title: const Text('Select Products & Discount'),
              backgroundColor: primary,
            ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: quantities.length, // Only unique product IDs
              itemBuilder: (context, index) {
                final productId = quantities.keys.elementAt(index);
                final product = widget.products.firstWhereOrNull((p) => p.id == productId) ?? Product(id: productId, name: 'Unknown', price: 0);
                final idx = widget.products.indexWhere((p) => p.id == productId);
                final isSelected = idx != -1 ? selectedIndices[idx] : false;
                final qty = quantities[productId] ?? 1;
                final percent = percentages[productId] ?? 0.0;
                final discountedPrice = discountedPrices[productId] ?? product.price;
                return ListTile(
                  onLongPress: () {
                    setState(() {
                      selectionMode = true;
                      if (idx != -1) selectedIndices[idx] = true;
                    });
                  },
                  onTap: selectionMode
                      ? () {
                          setState(() {
                            if (idx != -1) selectedIndices[idx] = !selectedIndices[idx];
                            if (selectedIndices.every((v) => !v)) {
                              selectionMode = false;
                            }
                          });
                        }
                      : null,
                  leading: selectionMode && isSelected
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (idx != -1) selectedIndices[idx] = val ?? false;
                              if (selectedIndices.every((v) => !v)) {
                                selectionMode = false;
                              }
                            });
                          },
                        )
                      : null,
                  title: Text(product.name),
                  subtitle: Text(
                    'Original: ₹${product.price.toStringAsFixed(2)} | Qty: $qty | Percentage: ${percent.toStringAsFixed(2)}% |(After percentage) Price: ₹${discountedPrice.toStringAsFixed(2)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${discountedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                          Text(
                            'Total: ₹${(discountedPrice * qty).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editProduct(product.id),
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
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                    Text(
                      '₹' + _calculateGrandTotal().toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30,
                      color: Colors.green
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 50.0,right: 50,bottom: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        // Build new product list with updated price and quantity for all products
                        final List<Product> finalProducts = [];
                        for (var p in widget.products) {
                          final qty = quantities[p.id] ?? 1;
                          final percent = percentages[p.id] ?? 0.0;
                          final price = _calculateDiscountedPrice(p.price, percent);
                          for (int i = 0; i < qty; i++) {
                            finalProducts.add(Product(id: p.id, name: p.name, price: price));
                          }
                        }
                        // Navigate to BillPage directly
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => BillPage(cart: finalProducts),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 30.0, right: 30.0,top: 5, bottom: 5),
                        child: Row(
                          children: [
                            Text(
                              'Go to Bill',
                              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold,
                              color: black
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.arrow_forward, size: 30, color: Colors.blue),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
