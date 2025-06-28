import 'package:flutter/material.dart';
import 'package:electrition_bill/moels/product.dart';
import 'package:electrition_bill/screens/billscreen.dart';

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
                decoration: const InputDecoration(labelText: 'Quantity'),
                onChanged: (_) {
                  setState(() {}); // force rebuild for total update
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: percentController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Discount %'),
                onChanged: (_) {
                  setState(() {}); // force rebuild for total update
                },
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
                final qty = int.tryParse(qtyController.text);
                final percent = double.tryParse(percentController.text);
                if (qty != null && qty > 0 && percent != null && percent >= 0 && percent <= 100) {
                  Navigator.of(context).pop({'qty': qty, 'percent': percent});
                }
              },
              child: const Text('OK'),
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
                    final allSelected = selectedIndices.every((v) => v);
                    for (int i = 0; i < selectedIndices.length; i++) {
                      selectedIndices[i] = !allSelected;
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
                                  child: const Text('No'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            setState(() {
                              for (int i = selectedIndices.length - 1; i >= 0; i--) {
                                if (selectedIndices[i]) {
                                  widget.products.removeAt(i);
                                  selectedIndices.removeAt(i);
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
                                  controller: percentController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Discount %'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final percent = double.tryParse(percentController.text);
                                      if (percent != null && percent >= 0 && percent <= 100) {
                                        Navigator.of(context).pop(percent);
                                      }
                                    },
                                    child: const Text('OK'),
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
            ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];
                final isSelected = selectedIndices[index];
                final qty = quantities[product.id] ?? 1;
                final percent = percentages[product.id] ?? 0.0;
                final discountedPrice = discountedPrices[product.id] ?? product.price;
                return ListTile(
                  onLongPress: () {
                    setState(() {
                      selectionMode = true;
                      selectedIndices[index] = true;
                    });
                  },
                  onTap: selectionMode
                      ? () {
                          setState(() {
                            selectedIndices[index] = !selectedIndices[index];
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
                              selectedIndices[index] = val ?? false;
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
                    const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(
                      '₹' + _calculateGrandTotal().toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
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
                    child: const Text('Go to Bill'),
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
