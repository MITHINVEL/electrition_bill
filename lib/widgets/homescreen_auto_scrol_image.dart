import 'package:electrition_bill/core/constant.dart';
import 'package:flutter/material.dart';

class ShopBannerCarousel extends StatefulWidget {
  const ShopBannerCarousel({super.key});

  @override
  State<ShopBannerCarousel> createState() => _ShopBannerCarouselState();
}

class _ShopBannerCarouselState extends State<ShopBannerCarousel> {
  final List<String> images = [
    'assets/images/png_images/shopname_homepage.jpg',
     'assets/images/png_images/shopbanner.jpg',
      'assets/images/png_images/shopname_homepage.jpg',
     // Add more images as needed
  ];
  int _currentIndex = 0;
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: 0);
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted) return;
    int nextPage = (_currentIndex + 1) % images.length;
    _controller.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentIndex = nextPage;
    });
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only( bottom: 10.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: black,
                  blurRadius: 10.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Image.asset(
                      images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentIndex == index ? Colors.pink : Colors.white,
                border: Border.all(color: Colors.pink, width: 1),
              ),
            );
          }),
        ),
      ],
    );
  }
}