
import 'package:electrition_bill/core/constant.dart';
import 'package:electrition_bill/moels/product.dart';
import 'package:electrition_bill/screens/billscreen.dart';
import 'package:electrition_bill/screens/home_screen.dart';
import 'package:electrition_bill/screens/prodectaddscreen.dart';
import 'package:electrition_bill/screens/profile.dart';
import 'package:electrition_bill/widgets/search.dart';


import 'package:flutter/material.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart'; // or wherever your addscreen is defined
class Bottomnavigation extends StatefulWidget {
  const Bottomnavigation({super.key});

  @override
  State<Bottomnavigation> createState() => _BottomnavigationState();
}

class _BottomnavigationState extends State<Bottomnavigation> {
  var selected = 0;
  List<Product> cart = [];

  void addToCart(Product product, {int quantity = 1}) {
    setState(() {
      for (int i = 0; i < quantity; i++) {
        cart.add(product);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Prevent RangeError by clamping selected index
    int safeIndex = selected;
    final pagelist = <Widget>[
      ProductListPage(cart: cart, addToCart: addToCart), // Home
      SearchPage(cart: cart, addToCart: addToCart), // Search (replace with SearchPage() if you have one)
      AddProductScreen(),
      BillPage(cart: cart),
      ProfilePage() // Add
      // Add more pages here for Notification and Profile if needed
    ];
    if (safeIndex >= pagelist.length) safeIndex = 0;
    return Scaffold(
      body: pagelist[safeIndex],
      bottomNavigationBar: StylishBottomBar(
        backgroundColor: primary,
        option: AnimatedBarOptions(
          iconStyle: IconStyle.animated,
          barAnimation: BarAnimation.transform3D,
          
        ),
        iconSpace: 12.0,
        items: [
          BottomBarItem(
            icon: const Icon(Icons.home, size: 35,),
            title: const Text('Home'),
            unSelectedColor: white,
            selectedColor: const Color.fromARGB(237, 142, 33, 243),
          ),
          BottomBarItem(
             unSelectedColor: white,
            icon: const Icon(Icons.search,size: 30,),
            title: const Text('Search'),
            selectedColor: Colors.purpleAccent.shade200, // Changed to a lighter purple
          ),
          BottomBarItem(
             unSelectedColor: white,
            icon: const Icon(Icons.add,size: 35,),
            title: const Text('Add'),
            selectedColor: Colors.purple,
          ),
          BottomBarItem(
            unSelectedColor: white,
            icon: const Icon(Icons.credit_card, size: 30,),
            title: const Text('Bill'),
            selectedColor: const Color.fromARGB(255, 39, 41, 176),
          ),
          
   BottomBarItem(
     unSelectedColor: white,
  icon:  CircleAvatar(
                radius: 19,
                backgroundImage: const AssetImage('assets/images/logos/logo.jpg'),
              ),
              title: const Text('Profile'),
             selectedColor: Colors.purple,
           ),
          
        ],
        hasNotch: true,
        currentIndex: selected,
        onTap: (index) {
          setState(() {
            selected = index;
          });
        },
      ),
    );
  }
}