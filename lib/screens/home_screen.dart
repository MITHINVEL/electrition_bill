import 'package:electrition_bill/core/constant.dart';
import 'package:electrition_bill/moels/product.dart';
import 'package:electrition_bill/screens/prodect_screen.dart';
import 'package:electrition_bill/widgets/homescreen_auto_scrol_image.dart';
import 'package:flutter/material.dart';

class ProductListPage extends StatefulWidget {
  final List<Product> cart;
  final void Function(Product, {int quantity}) addToCart;
  const ProductListPage({super.key, required this.cart, required this.addToCart});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DURGA  ELECTRICALS',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          fontFamily: 'Roboto',
        )),
       backgroundColor: primary,
        actions: [
          IconButton(
              icon: CircleAvatar(
                radius: 29,
                backgroundImage: const AssetImage('assets/images/logos/logo.jpg'),
              ),
              onPressed: () {
              },
            ),
          
        ],
      ),
   backgroundColor: white,
      body:
       Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pink, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductStorePage(
                          cart: widget.cart,
                          addToCart: widget.addToCart,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Welcome to Durga Electricals!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.pink,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Tap here to view all products and manage your shop inventory.',
                        style: TextStyle(fontSize: 15, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
                  const SizedBox(height: 20),
              ShopBannerCarousel(),
              const SizedBox(height: 35),
              Container(
       margin: EdgeInsets.symmetric(horizontal: 1, vertical: 0),
    
                decoration: BoxDecoration(
            
                  borderRadius: BorderRadius.circular(24),
                 
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 10, 10, 10).withOpacity(0.4),
                      blurRadius: 10.0,
                      offset: const Offset(1, 10),
                    ),
                  ],
                ),
                child:ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                child:SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/images/png_images/durga_electricals.jpg',
                    fit: BoxFit.cover,
                    
                  ),
                )
           ))
            ],
          ),
        ),
      ),
          );
        
      
    
  }
}
