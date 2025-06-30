import 'package:flutter/material.dart';
import 'package:electrition_bill/routing/bottomnavigationbar.dart';

class CustomSplashScreen extends StatefulWidget {
  const CustomSplashScreen({super.key});
  @override
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1720), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Bottomnavigation()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 10, 10),
      body: Stack(
        children: [
          Center(
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 253, 251, 251),
                    blurRadius: 10.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/png_images/durga_electricals.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/png_images/branding_mithinvel.jpg', width: 100),
                  const SizedBox(width: 10),
              
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}