import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:imagekit_io/imagekit_io.dart';
import 'pick_and_upload_image.dart';

class AddProductPage extends StatefulWidget {
  final Future<void> Function(String, String, String, File?, Function) addProductPermanently;
  const AddProductPage({Key? key, required this.addProductPermanently}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  String name = '';
  String price = '';
  String imageUrl = '';
  File? imageFile;
  bool isUploading = false;
  bool hasShownInvalidUrl = false;
  final picker = ImagePicker();

  // Helper function for compute to compress/resize image in background
  Future<String> compressAndResizeImage(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded != null) {
      final resized = img.copyResize(decoded, width: 800);
      final compressed = img.encodeJpg(resized, quality: 70);
      final tempDir = Directory.systemTemp;
      final tempFile = await File('${tempDir.path}/temp_upload.jpg').writeAsBytes(compressed);
      return tempFile.path;
    } else {
      return filePath;
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => isUploading = true);
      // Use compute to process image in background
      final processedPath = await compute<String, String>(
        (path) {
          final file = File(path);
          final bytes = file.readAsBytesSync();
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            final resized = img.copyResize(decoded, width: 800);
            final compressed = img.encodeJpg(resized, quality: 70);
            final tempDir = Directory.systemTemp;
            final tempFile = File('${tempDir.path}/temp_upload.jpg')..writeAsBytesSync(compressed);
            return tempFile.path;
          } else {
            return path;
          }
        },
        pickedFile.path,
      );
      setState(() {
        imageFile = File(processedPath);
        isUploading = false;
      });
    }
  }

  Future<String?> _getLanIp() async {
    try {
      // Try Windows ipconfig first
      if (io.Platform.isWindows) {
        final result = await io.Process.run('ipconfig', []);
        final output = result.stdout.toString();
        final regex = RegExp(r'IPv4 Address[. ]*: ([0-9.]+)');
        final match = regex.firstMatch(output);
        if (match != null) {
          final ip = match.group(1);
          if (ip != null && (ip.startsWith('192.') || ip.startsWith('10.') || ip.startsWith('172.'))) {
            return ip;
          }
        }
      }
      // Try all interfaces (Linux/Mac/Windows fallback)
      final interfaces = await io.NetworkInterface.list(type: io.InternetAddressType.IPv4, includeLinkLocal: false);
      for (final i in interfaces) {
        for (final addr in i.addresses) {
          if (!addr.isLoopback && (addr.address.startsWith('192.') || addr.address.startsWith('10.') ||
              (addr.address.startsWith('172.') && int.tryParse(addr.address.split('.')[1]) != null &&
                int.parse(addr.address.split('.')[1]) >= 16 && int.parse(addr.address.split('.')[1]) <= 31))) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('LAN IP detection error: $e');
    }
    return null;
  }

  Future<void> addProductToHttpServer(String name, String price, String imageUrl, File? imageFile) async {
    const int maxRetries = 3;
    int attempt = 0;
    int delayMs = 1000;
    while (attempt < maxRetries) {
      try {
        // Only upload to ImageKit, do not use Node.js server
        String? imageKitUrl = imageUrl;
        if (imageFile != null) {
          imageKitUrl = await uploadImageToImageKit(imageFile);
          if (imageKitUrl == null) {
            throw Exception('Failed to upload image to ImageKit');
          }
        }
        // Call the permanent add function with the ImageKit URL
        await widget.addProductPermanently(name, price, imageKitUrl, imageFile, (void Function() fn) => setState(fn));
        return;
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image after $maxRetries attempts. Please check your network and ImageKit credentials.')),
            );
          }
          rethrow;
        } else {
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs *= 2;
        }
      }
    }
  }

  Future<String?> uploadImageToImageKit(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final response = await ImageKit.io(
        bytes,
        // Use your ImageKit public API key
        privateKey: 'private_SuLidoBzwScNVCCpwEH8J34gBUQ=', // Use your ImageKit private API key
        fileName: imageFile.path.split('/').last, // Always use the actual file name
        onUploadProgress: (progress) {
          // Optionally handle progress
        },
      );
      if (response.url != null) {
        return response.url;
      } else {
        return null;
      }
    } catch (e) {
      print('ImageKit upload error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                if (imageFile != null) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PickAndUploadImagePage(
                        imageFile: imageFile,
                        onDelete: () {
                          setState(() {
                            imageFile = null;
                            imageUrl = '';
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: imageFile != null
                        ? Stack(
                            children: [
                              Image.file(imageFile!, fit: BoxFit.cover, width: 120, height: 120),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      imageFile = null;
                                      imageUrl = '';
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete, color: Colors.red, size: 24),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload Image'),
                    onPressed: isUploading
                        ? null
                        : () async {
                            await pickImage();
                            setState(() {});
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Product Name'),
              onChanged: (value) => setState(() => name = value),
              onSubmitted: (_) async {
                if (!isUploading && name.isNotEmpty && double.tryParse(price) != null && (imageFile != null || imageUrl.isNotEmpty)) {
                  setState(() => isUploading = true);
                  await addProductToHttpServer(name, price, imageUrl, imageFile);
                  await widget.addProductPermanently(name, price, imageUrl, imageFile, (void Function() fn) => setState(fn));
                  setState(() {
                    isUploading = false;
                    imageFile = null;
                    imageUrl = '';
                    name = '';
                    price = '';
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product added successfully!')),
                    );
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() => price = value),
              onSubmitted: (_) async {
                if (!isUploading && name.isNotEmpty && double.tryParse(price) != null && (imageFile != null || imageUrl.isNotEmpty)) {
                  setState(() => isUploading = true);
                  await addProductToHttpServer(name, price, imageUrl, imageFile);
                  await widget.addProductPermanently(name, price, imageUrl, imageFile, (void Function() fn) => setState(fn));
                  setState(() {
                    isUploading = true;
                    imageFile = null;
                    imageUrl = '';
                    name = '';
                    price = '';
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Product added successfully!')),
                    );
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              },
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Image URL (optional)'),
              onChanged: (value) {
                setState(() {
                  imageUrl = value;
                  hasShownInvalidUrl = false; // Reset flag on change
                });
              },
            ),
            if (isUploading)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (name.isNotEmpty && double.tryParse(price) != null && (imageFile != null || (imageUrl.isNotEmpty && imageUrl.startsWith('http')))) {
                            Navigator.of(context).pop(); // Quickly go back to home page
                            try {
                              String? finalImageUrl = imageUrl.isNotEmpty && imageUrl.startsWith('http') ? imageUrl : null;
                              if (imageFile != null) {
                                final uploadedUrl = await uploadImageToImageKit(imageFile!);
                                if (uploadedUrl != null) {
                                  finalImageUrl = uploadedUrl;
                                } else {
                                  throw Exception('ImageKit upload failed');
                                }
                              }
                              await widget.addProductPermanently(name, price, finalImageUrl ?? '', imageFile, (void Function() fn) => setState(fn));
                            } catch (e) {
                              // Optionally show error after navigation
                            }
                          }
                        },
                  child: const Text('Add Product'),
                ),
                ElevatedButton(
                  onPressed: (imageFile != null || imageUrl.isNotEmpty)
                      ? () {
                          setState(() {
                            imageFile = null;
                            imageUrl = '';
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
