import 'package:electrition_bill/cart_page.dart' as cart_page;
import 'package:electrition_bill/prodect_ditails_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'firebase_options.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'dart:convert'; // For base64 encoding
import 'add_product.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Product model
class Product {
  final String id; // Firestore document id
  final String name;
  final double price;
  final String imageUrl;
  Product({required this.id, required this.name, required this.price, required this.imageUrl});

  // Factory constructor to create Product from Firestore document
  factory Product.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Electrition Bill',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Electrition Bill'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Product> products = [];
  List<Product> cart = [];
  String searchQuery = '';
  int _selectedIndex = 0;
  DocumentSnapshot? lastDocument;

  bool hasMore = true;
  final int pageSize = 20;

  // Add this to track product quantities
  Map<String, int> productQuantities = {};

  @override
  void initState() {
    super.initState();
    _loadCartFromPrefs();
    _fetchProductsFromFirestore();
  }
  void updateProductDialog(Product product) {
    String name = product.name;
    String price = product.price.toString();
    String imageUrl = product.imageUrl;
    File? imageFile;
    bool isUploading = false;
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController priceController = TextEditingController(text: price);
    TextEditingController imageUrlController = TextEditingController(text: imageUrl);

    final picker = ImagePicker();

    Future<void> pickImage({bool fromCamera = true}) async {
      final pickedFile = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );
      if (pickedFile != null) {
        imageFile = File(pickedFile.path);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Update Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await pickImage(fromCamera: false);
                        setStateDialog(() {});
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: imageFile != null
                            ? Image.file(imageFile!, fit: BoxFit.cover)
                            : (imageUrl.isNotEmpty && imageUrl.startsWith('http')
                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                : const Icon(Icons.camera_alt, size: 40, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                      onChanged: (value) => name = value,
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => price = value,
                    ),
                    TextField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL (optional)'),
                      onChanged: (value) => imageUrl = value,
                    ),
                    if (isUploading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (nameController.text.isNotEmpty &&
                              double.tryParse(priceController.text) != null) {
                            isUploading = true;
                            setStateDialog(() {});
                            String finalImageUrl = imageUrlController.text;
                            if (imageFile != null) {
                              final uploadedUrl = await uploadImage(imageFile!, context: context);
                              if (uploadedUrl != null) {
                                finalImageUrl = uploadedUrl;
                                imageUrlController.text = uploadedUrl;
                              }
                            }
                            await updateProductInFirestore(
                              product.id,
                              nameController.text,
                              double.parse(priceController.text),
                              finalImageUrl,
                            );
                            isUploading = false;
                            setStateDialog(() {});
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Product updated successfully!')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill all fields.')),
                            );
                          }
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchProductsFromFirestore() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('products').get();
    setState(() {
      products = querySnapshot.docs.map((doc) => Product.fromDoc(doc)).toList();
    });
  }

  Future<void> _loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getStringList('cart');
    if (cartJson != null) {
      setState(() {
        cart = cartJson.map((item) {
          final data = item.split('|');
          return Product(
            id: data[0],
            name: data[1],
            price: double.tryParse(data[2]) ?? 0.0,
            imageUrl: data[3],
          );
        }).toList();
      });
    }
  }

  Future<void> _saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = cart.map((p) => '${p.id}|${p.name}|${p.price}|${p.imageUrl}').toList();
    await prefs.setStringList('cart', cartJson);
  }

  List<Product> get filteredProducts {
    if (searchQuery.isEmpty) return products;
    return products.where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
  }

  void addToCart(Product product) async {
    setState(() {
      cart.add(product);
    });
    await _saveCartToPrefs();
    // Store cart addition to backend (Firestore, e.g. 'cart' collection)
    await FirebaseFirestore.instance.collection('cart').add({
      'productId': product.id,
      'name': product.name,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'addedAt': FieldValue.serverTimestamp(),
    });
    // Optionally, you can show a snackbar or feedback here
  }

  // Utility to upload image, used by both dialog and permanent add
  Future<String?> uploadImage(File file, {BuildContext? context, String folderName = ''}) async {
    try {
      if (!file.existsSync()) {
        print('Image file does not exist');
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image file does not exist.')),
          );
        }
        return null;
      }
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final folder = (folderName.isNotEmpty) ? folderName : 'product_images';
      final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');
      print('Uploading image to Firebase Storage: $folder/$fileName');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      print('Image uploaded. Download URL: $url');
      return url;
    } catch (e) {
      print('Image upload error: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
      return null;
    }
  }

 
  Future<String?> uploadImageToNodeServer(File imageFile) async {
    try {

      final uri = Uri.parse('http://192.168.158.51:3000/api/upload');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final respJson = json.decode(respStr);
        // The backend returns a relative URL, so prepend the server address
        return 'http://192.168.158.51:3000${respJson['url']}';
      } else {
        print('Node.js upload failed: \\${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Node.js upload error: $e');
      return null;
    }
  }

  // Upload image to ImageKit
  Future<String?> uploadImageToImageKit(File imageFile) async {
    try {
      final url = Uri.parse('https://upload.imagekit.io/api/v1/files/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['fileName'] = imageFile.path.split('/').last
        ..fields['publicKey'] = 'private_SuLidoBzwScNVCCpwEH8J34gBUQ='
        ..fields['folder'] = '/product_images/'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      // Add authentication header
      request.headers['Authorization'] = 'private_SuLidoBzwScNVCCpwEH8J34gBUQ='; // base64(private_key:)
      final response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final respJson = json.decode(respStr);
        return respJson['url'];
      } else {
        print('ImageKit upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('ImageKit upload error: $e');
      return null;
    }
  }

  Future<void> addProductPermanently(String name, String price, String imageUrl, File? imageFile, Function setStateDialog, {String folderName = ''}) async {
    setStateDialog(() {});
    String finalImageUrl = imageUrl;
    if (imageFile != null) {
      // Upload to Firebase Storage in the selected folder
      final uploadedUrl = await uploadImage(imageFile, folderName: folderName, context: context);
      if (uploadedUrl != null) {
        finalImageUrl = uploadedUrl;
      }
    }
    // Create the new product locally first for instant UI feedback
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final newProduct = Product(
      id: tempId,
      name: name,
      price: double.parse(price),
      imageUrl: finalImageUrl,
    );
    setState(() {
      products.add(newProduct);
    });
    // Add to Firestore and update the product with the real Firestore ID
    final docRef = await FirebaseFirestore.instance.collection('products').add({
      'name': name,
      'price': double.parse(price),
      'imageUrl': finalImageUrl,
    });
    setState(() {
      // Replace the temp product with the one with the real Firestore ID
      final idx = products.indexWhere((p) => p.id == tempId);
      if (idx != -1) {
        products[idx] = Product(
          id: docRef.id,
          name: name,
          price: double.parse(price),
          imageUrl: finalImageUrl,
        );
      }
    });
    setStateDialog(() {});
  }

  void addProductDialog() {
    // Move imageFile, imageUrl, and controllers outside the builder for persistence
    String name = '';
    String price = '';
    String imageUrl = '';
    String folderName = '';
    File? imageFile;
    final picker = ImagePicker();
    bool isUploading = false;
    TextEditingController imageUrlController = TextEditingController();
    FocusNode imageUrlFocusNode = FocusNode();

    Future<void> pickImage({bool fromCamera = true}) async {
      final pickedFile = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      );
      if (pickedFile != null) {
        final originalFile = File(pickedFile.path);
        final bytes = await originalFile.readAsBytes();
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final resized = img.copyResize(decoded, width: 800);
          final compressed = img.encodeJpg(resized, quality: 70);
          final tempDir = Directory.systemTemp;
          final tempFile = await File('${tempDir.path}/temp_upload.jpg').writeAsBytes(compressed);
          imageFile = tempFile;
        } else {
          imageFile = originalFile;
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Take Photo'),
                                    onTap: () async {
                                      Navigator.of(context).pop();
                                      await pickImage(fromCamera: true);
                                      setStateDialog(() {});
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('Pick from Gallery'),
                                    onTap: () async {
                                      Navigator.of(context).pop();
                                      await pickImage(fromCamera: false);
                                      setStateDialog(() {});
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.link),
                                    title: const Text('Enter Image URL'),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      Future.delayed(const Duration(milliseconds: 200), () {
                                        FocusScope.of(context).requestFocus(imageUrlFocusNode);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: imageFile != null
                            ? Image.file(imageFile!, fit: BoxFit.cover)
                            : (imageUrl.isNotEmpty && imageUrl.startsWith('http')
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (imageUrl.isNotEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Invalid image URL!')),
                                          );
                                        }
                                      });
                                      return const Icon(Icons.error, size: 40, color: Colors.red);
                                    },
                                  )
                                : const Icon(Icons.camera_alt, size: 40, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Product Name'),
                      onChanged: (value) => name = value,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => price = value,
                    ),
                    TextField(
                      controller: imageUrlController,
                      focusNode: imageUrlFocusNode,
                      decoration: const InputDecoration(labelText: 'Image URL (optional)'),
                      onChanged: (value) => imageUrl = value,
                      enableInteractiveSelection: true,
                      toolbarOptions: const ToolbarOptions(
                        copy: true,
                        paste: true,
                        cut: true,
                        selectAll: true,
                      ),
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Folder Name (for upload)'),
                      onChanged: (value) => folderName = value,
                    ),
                    if (isUploading) const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: CircularProgressIndicator(),
                    ),
                    if (imageFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Upload Image'),
                        onPressed: isUploading
                            ? null
                            : () async {
                                // Open gallery and pick image
                                await pickImage(fromCamera: false);
                                setStateDialog(() {});
                                if (imageFile != null) {
                                  isUploading = true;
                                  setStateDialog(() {});
                                  final uploadedUrl = await uploadImage(
                                    imageFile!,
                                    folderName: folderName,
                                    context: context,
                                  );
                                  isUploading = false;
                                  setStateDialog(() {});
                                  if (uploadedUrl != null) {
                                    imageUrl = uploadedUrl;
                                    imageUrlController.text = uploadedUrl;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Image uploaded successfully!')),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Image upload failed!')),
                                    );
                                  }
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUploading ? null : () async {
                    if (name.isNotEmpty && double.tryParse(price) != null && (imageFile != null || imageUrl.isNotEmpty)) {
                      isUploading = true;
                      setStateDialog(() {});
                      String finalImageUrl = imageUrl;
                      if (imageFile != null) {
                        final uploadedUrl = await uploadImageToImageKit(imageFile!);
                        if (uploadedUrl != null) {
                          finalImageUrl = uploadedUrl;
                          imageUrlController.text = uploadedUrl;
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ImageKit upload failed!')),
                          );
                          isUploading = false;
                          setStateDialog(() {});
                          return;
                        }
                      }
                      await addProductPermanently(name, price, finalImageUrl, null, setStateDialog, folderName: folderName);
                      isUploading = false;
                      setStateDialog(() {});
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Product added successfully!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please provide all required fields and an image.')),
                      );
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void deleteProduct(Product product) async {
    setState(() {
      products.removeWhere((p) => p.id == product.id);
    });
    // Remove from Firestore
    await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
    // Remove image from ImageKit if imageUrl is an ImageKit URL
    if (product.imageUrl.isNotEmpty && product.imageUrl.contains('imagekit')) {
      try {
        final fileId = Uri.parse(product.imageUrl).pathSegments.last;
        final privateKey = '<YOUR_IMAGEKIT_PRIVATE_API_KEY>';
        final authHeader = 'Basic ' + base64Encode(utf8.encode('$privateKey:'));
        await http.delete(
          Uri.parse('https://api.imagekit.io/v1/files/$fileId'),
          headers: {
            'Authorization': authHeader,
          },
        );
      } catch (e) {
        // Optionally handle error
      }
    }
  }

  void _onNavBarTap(int index) {
    if (index == 1) {
      openCart();
    } else if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ProfilePage(),
        ),
      );
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void removeFromCart(Product product) async {
    setState(() {
      cart.remove(product);
    });
    await _saveCartToPrefs();
  }

  void openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => cart_page.CartScreen(cart: cart, removeFromCart: removeFromCart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              // Navigate to the AddProductPage and refresh products after
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddProductPage(
                    addProductPermanently: addProductPermanently,
                  ),
                ),
              );
              
            },
            tooltip: 'Add Product',
          ),
          IconButton(
            icon: Icon(
              Icons.shopping_cart,
              color: _selectedIndex == 1 ? Colors.blue[900] : null, // Dark blue when cart selected
            ),
            onPressed: openCart,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Product',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
               
                return false;
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  if (index >= filteredProducts.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final product = filteredProducts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductDetailPage(
                            product: product,
                            addToCart: addToCart,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: product.imageUrl.startsWith('http')
                                  ? Image.network(product.imageUrl, fit: BoxFit.contain)
                                  : const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            ),
                          ),
                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: const Text('Are you sure you want to delete this product?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('No'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(true); // Close dialog immediately
                                            removeFromCart(product); // Remove product immediately
                                          },
                                          child: const Text('Yes'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    deleteProduct(product);
                                  }
                                },
                                tooltip: 'Delete Product',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.shopping_cart,
                                  color: cart.contains(product) ? Colors.blueGrey : Colors.grey,
                                ),
                                tooltip: cart.contains(product) ? 'Added to Cart' : 'Add to Cart',
                                onPressed: () {
                                  if (!cart.contains(product)) {
                                    addToCart(product);
                                    setState(() {}); // To update icon color
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${product.name} added to cart!')),
                                    );
                                    // If this is the add product screen, pop after adding
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          // Add quantity controls
                          
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            openCart();
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProfilePage(),
              ),
            );
          }
          setState(() {
            _selectedIndex = index;
          });
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

  Future<void> updateProductInFirestore(String id, String name, double price, String imageUrl) async {
    await FirebaseFirestore.instance.collection('products').doc(id).update({
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
    });
    // Update local list
    setState(() {
      final idx = products.indexWhere((p) => p.id == id);
      if (idx != -1) {
        products[idx] = Product(id: id, name: name, price: price, imageUrl: imageUrl);
      }
    });
  }
}



// Product Detail Page
