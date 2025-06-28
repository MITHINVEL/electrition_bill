import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedLampRow extends StatefulWidget {
  final List<String> imagePaths;
  final int animationDelay;
  const AnimatedLampRow({required this.imagePaths, this.animationDelay = 0, Key? key}) : super(key: key);

  @override
  State<AnimatedLampRow> createState() => _AnimatedLampRowState();
}

class _AnimatedLampRowState extends State<AnimatedLampRow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late ScrollController _scrollController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 30 + widget.animationDelay),
    )..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  void _startAutoScroll() {
    // Make the scroll extremely fast by increasing the increment and keeping the timer interval very low
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      double next = current + 2.0; // Much faster scroll
      if (next >= maxScroll) {
        next = 0;
      }
      _scrollController.jumpTo(next);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ListView.builder(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.imagePaths.length * 1000, // repeat for infinite effect
            itemBuilder: (context, index) {
              final path = widget.imagePaths[index % widget.imagePaths.length];
              return Transform.scale(
                scale: _animation.value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24), // rectangle with rounded corners
                    child: Image.asset(
                      path,
                      width: 150,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
