import 'package:electrition_bill/core/constant.dart';
import 'package:electrition_bill/moels/product.dart';
import 'package:electrition_bill/widgets/animated_lamp_row.dart';

import 'package:electrition_bill/screens/prodect_screen.dart';
import 'package:electrition_bill/widgets/autoscroll_light.dart';
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
        title: const Text('DURGA ELECTRICALS',
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
              onPressed: () {},
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
                  const SizedBox(height: 15),
              ShopBannerCarousel(),
              const SizedBox(height: 10),
              const Text(
                'Home Light Collection',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 10),
              // First animation row (first half of stylist lamp images)
              AnimatedLampRow(
                imagePaths: [
                  'assets/images/stylist_lamp/lamp2.jpg',
                  'assets/images/stylist_lamp/lamp3.jpg',
                  'assets/images/stylist_lamp/lamp4.jpg',
                  'assets/images/stylist_lamp/lamp5.jpg',
                  'assets/images/stylist_lamp/lamp6.jpg',
                  'assets/images/stylist_lamp/lamp7.jpg',
                  'assets/images/stylist_lamp/lamp8.jpg',
                  'assets/images/stylist_lamp/lamp9.jpg',
                  'assets/images/stylist_lamp/lamp10.jpg',
                  'assets/images/stylist_lamp/lamp11.jpg',
                  'assets/images/stylist_lamp/lamp12.jpg',
                  'assets/images/stylist_lamp/lamp13.jpg',
                  'assets/images/stylist_lamp/lamp14.jpg',
                  'assets/images/stylist_lamp/lamp15.jpg',
                  'assets/images/stylist_lamp/lamp16.jpg',
                ],
                animationDelay: 0,
              ),
              const SizedBox(height: 20),
              // Second animation row (second half of stylist lamp images)
    
              
            ],
          ),
        ),
      ),
          );
        
      
    
  }
}
