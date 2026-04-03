import 'package:flutter/material.dart';
import '../utils/theme.dart';

class PerformanceTicker extends StatefulWidget {
  const PerformanceTicker({super.key});

  @override
  State<PerformanceTicker> createState() => _PerformanceTickerState();
}

class _PerformanceTickerState extends State<PerformanceTicker> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  final List<String> _stats = [
    'FPS: 28.4',
    'LATENCY: 85ms',
    'CORE: QUANTIZED_V3',
    'MEM: 124.6MB',
    'TEMP: OPTIMAL',
    'SIGNAL: -62dBm',
    'UPLINK: ACTIVE',
    'BUFFER: 1.2s',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _animationController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _animationController.value * maxScroll;
        _scrollController.jumpTo(currentScroll);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.5),
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 1000,
        itemBuilder: (context, index) {
          final stat = _stats[index % _stats.length];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Row(
                children: [
                  Container(
                    width: 4, height: 4,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stat,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
