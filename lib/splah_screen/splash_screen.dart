import 'package:electrition_bill/core/constant.dart';
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
    Future.delayed(const Duration(milliseconds: 2500), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Bottomnavigation()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 8.0, top: 8.0, bottom: 8.0),
              child: Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                
                ),
                child: Image.asset(
                  'assets/images/png_images/splash.png',
                  fit: BoxFit.cover,
                ),
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
                  Image.asset('assets/images/png_images/branding_mithinvel.png', width: 100),
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