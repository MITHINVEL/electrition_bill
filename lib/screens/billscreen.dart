import 'dart:io';

import 'package:electrition_bill/moels/product.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

class BillPage extends StatefulWidget {
  final List<Product> cart;
  const BillPage({super.key, required this.cart});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  Map<String, int> productCounts = {};
  Map<String, double> productPrices = {};

  @override
  void initState() {
    super.initState();
    for (var product in widget.cart) {
      productCounts[product.id] = (productCounts[product.id] ?? 0) + 1;
      productPrices[product.id] = product.price;
    }
  }

  void _updateCount(String productId, int newCount) {
    setState(() {
      if (newCount > 0) {
        productCounts[productId] = newCount;
      }
    });
  }

  void _removeProduct(String productId) {
    setState(() {
      productCounts.remove(productId);
      // Do NOT remove from widget.cart; just hide from bill view
    });
  }

  void _removeProductAt(int index) {
    setState(() {
      final uniqueProducts = widget.cart.toSet().toList();
      final product = uniqueProducts[index];
      // Remove only one instance from cart
      final cartIndex = widget.cart.indexWhere((p) => p.id == product.id);
      if (cartIndex != -1) {
        widget.cart.removeAt(cartIndex);
        // Update productCounts
        if (productCounts[product.id] != null) {
          if (productCounts[product.id]! > 1) {
            productCounts[product.id] = productCounts[product.id]! - 1;
          } else {
            productCounts.remove(product.id);
          }
        }
      }
    });
  }

  Future<bool> _requestStoragePermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 30) {
        if (await Permission.manageExternalStorage.isGranted) return true;
        var status = await Permission.manageExternalStorage.request();
        if (status.isGranted) return true;
        if (status.isPermanentlyDenied) {
          // Show dialog to guide user
          if (context.mounted) {
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Permission Required'),
                content: const Text(
                  'To save bills in Downloads, please allow "All files access" for this app:\n\n1. Tap "Go to Settings" below.\n2. Tap "All files access".\n3. Find and enable for this app.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      openAppSettings();
                    },
                    child: const Text('Go to Settings'),
                  ),
                ],
              ),
            );
          }
          return false;
        }
        // If denied, show dialog
        if (status.isDenied) {
          if (context.mounted) {
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Permission Needed'),
                content: const Text('Please allow "All files access" in settings to save bills in Downloads.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return false;
        }
        return false;
      } else {
        // Android < 11
        if (await Permission.storage.isGranted) return true;
        var storageStatus = await Permission.storage.request();
        if (storageStatus.isGranted) return true;
        if (storageStatus.isPermanentlyDenied) {
          await openAppSettings();
        }
        return false;
      }
    } else {
      var status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = 0;
    widget.cart.toSet().forEach((product) {
      final count = productCounts[product.id] ?? 1;
      final price = productPrices[product.id] ?? product.price;
      total += price * count;
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Bill',
            onPressed: () async {
              bool granted = await _requestStoragePermission();
              if (!granted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Storage permission denied. Please allow storage permission in settings.')),
                );
                return;
              }
              // PDF bill generation (use current productCounts/prices)
              final pdf = pw.Document();
              // Load background image
              final bgImageBytes = await rootBundle.load('assets/logos/pdfbackground.jpg');
              final bgImage = pw.MemoryImage(bgImageBytes.buffer.asUint8List());
              final now = DateTime.now();
              final formattedDate = DateFormat('dd-MM-yyyy').format(now);
              final formattedTime = DateFormat('hh:mm:ss a').format(now); // 12-hour format with AM/PM
              pdf.addPage(
                pw.Page(
                  build: (pw.Context context) {
                    return pw.Stack(
                      children: [
                        pw.Positioned.fill(
                          child: pw.Image(bgImage, fit: pw.BoxFit.cover),
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.end,
                              children: [
                                pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                                  children: [
                                    pw.Text('Date: $formattedDate', style: pw.TextStyle(fontSize: 12)),
                                    pw.Text('Time: $formattedTime', style: pw.TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text('DURGA ELECTRICALS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                              pw.Text('Pennagaram main Road,B Agraharam', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                            pw.Text('Cell: 7373478899,9787677881', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                            pw.SizedBox(height: 16),
                            pw.Table(
                              border: pw.TableBorder.all(),
                              children: [
                                pw.TableRow(
                                  children: [
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Product Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                                  ],
                                ),
                                ...productCounts.entries.map((entry) {
                                  final product = widget.cart.firstWhere((p) => p.id == entry.key);
                                  final count = entry.value;
                                  final price = productPrices[entry.key] ?? product.price;
                                  return pw.TableRow(
                                    children: [
                                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(product.name)),
                                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(count.toString())),
                                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(price.toStringAsFixed(2))),
                                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((price * count).toStringAsFixed(2))),
                                    ],
                                  );
                                }).toList(),
                                pw.TableRow(
                                  children: [
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('')),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('')),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(
                                      productCounts.entries.fold(0.0, (sum, entry) {
                                        final price = productPrices[entry.key] ?? 0.0;
                                        return sum + price * entry.value;
                                      }).toStringAsFixed(2),
                                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              );
              try {
                // Save bill products to a text file as well as PDF
                final StringBuffer billText = StringBuffer();
                billText.writeln('DURGA ELECTRICALS');
                billText.writeln('Pennagaram main Road,B Agraharam');
                billText.writeln('Cell: 7373478899,9787677881');
                billText.writeln('-----------------------------');
                billText.writeln('Product Name | Qty | Price | Total');
                double grandTotal = 0;
                productCounts.forEach((id, count) {
                  final product = widget.cart.firstWhere((p) => p.id == id);
                  final price = productPrices[id] ?? product.price;
                  final total = price * count;
                  grandTotal += total;
                  billText.writeln('${product.name} | $count | ₹${price.toStringAsFixed(2)} | ₹${total.toStringAsFixed(2)}');
                });
                billText.writeln('-----------------------------');
                billText.writeln('Total: ₹${grandTotal.toStringAsFixed(2)}');
                Directory? downloadsDir;
                String? debugPath;
                try {
                  if (Platform.isAndroid) {
                    final androidInfo = await DeviceInfoPlugin().androidInfo;
                    final sdkInt = androidInfo.version.sdkInt;
                    if (sdkInt >= 30 && !await Permission.manageExternalStorage.isGranted) {
                      // Fallback to app-specific directory if no permission
                      downloadsDir = await getExternalStorageDirectory();
                    } else {
                      final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
                      if (dirs != null && dirs.isNotEmpty) {
                        downloadsDir = dirs.first;
                      } else {
                        downloadsDir = await getExternalStorageDirectory();
                      }
                      if (downloadsDir == null || !(await downloadsDir.exists())) {
                        try {
                          downloadsDir = Directory('/storage/emulated/0/Download');
                          if (!await downloadsDir.exists()) {
                            await downloadsDir.create(recursive: true);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Download folder access failed: $e')),
                          );
                          return;
                        }
                      }
                    }
                  } else {
                    downloadsDir = await getApplicationDocumentsDirectory();
                  }
                  if (downloadsDir == null) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not find a valid directory to save the PDF.')),
                    );
                    return;
                  }
                  debugPath = downloadsDir.path;
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  final pdfPath = '${downloadsDir.path}/electrition_bill_$timestamp.pdf';
                  final txtPath = '${downloadsDir.path}/electrition_bill_$timestamp.txt';
                  final pdfFile = File(pdfPath);
                  final txtFile = File(txtPath);
                  try {
                    await pdfFile.writeAsBytes(await pdf.save());
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF file write failed: $e')),
                    );
                    return;
                  }
                  try {
                    await txtFile.writeAsString(billText.toString());
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Text file write failed: $e')),
                    );
                    return;
                  }
                  // Check if both files exist and show correct message
                  final pdfExists = await pdfFile.exists();
                  final txtExists = await txtFile.exists();
                  if (pdfExists && txtExists) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF & Product list saved!\nPath: $pdfPath')),
                    );
                  } else {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bill save failed. Please try again.')),
                    );
                  }
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF download fail: $e\nPath: \\${debugPath ?? "unknown"}')),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('An error occurred: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.cart.toSet().length,
              itemBuilder: (context, index) {
                final uniqueProducts = widget.cart.toSet().toList();
                final product = uniqueProducts[index];
                final count = productCounts[product.id] ?? 1;
                final totalProduct = (productPrices[product.id] ?? product.price) * count;
                if (!productCounts.containsKey(product.id)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Row(
                    children: [
                      
                      Expanded(
                        flex: 8,
                        child: GestureDetector(
                          onTap: () async {
                            final countController = TextEditingController(text: count.toString());
                            final priceController = TextEditingController(text: (productPrices[product.id] ?? product.price).toStringAsFixed(2));
                            final result = await showDialog<Map<String, dynamic>>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: Text('Edit ${product.name}'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: countController,
                                        keyboardType: TextInputType.number,
                                        autofocus: true,
                                        decoration: const InputDecoration(labelText: 'Count'),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: priceController,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(labelText: 'Price'),
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
                                        final val = int.tryParse(countController.text);
                                        final priceVal = double.tryParse(priceController.text);
                                        if (val != null && val > 0 && priceVal != null && priceVal > 0) {
                                          Navigator.of(context).pop({'count': val, 'price': priceVal});
                                        }
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (result != null && result['count'] != null && result['price'] != null) {
                              _updateCount(product.id, result['count']);
                              setState(() {
                                productPrices[product.id] = result['price'];
                              });
                            }
                          },
                          child: Text(
                            '${product.name}\n₹${(productPrices[product.id] ?? product.price).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, decoration: TextDecoration.underline, color: Colors.blue),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: GestureDetector(
                            onTap: () async {
                              final controller = TextEditingController(text: count.toString());
                              final newCount = await showDialog<int>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Edit Count for ${product.name}'),
                                    content: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      autofocus: true,
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
                              if (newCount != null && newCount > 0) {
                                _updateCount(product.id, newCount);
                              }
                            },
                            child: Text(
                              'x$count',
                              style: const TextStyle(fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              color: Colors.blue),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '₹${totalProduct.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _removeProductAt(index);
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}