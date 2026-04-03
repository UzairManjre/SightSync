import 'package:flutter/material.dart';
import 'dart:math';

class SlideToAdvance extends StatefulWidget {
  final VoidCallback onSlideComplete;
  final String label;

  const SlideToAdvance({
    required this.onSlideComplete,
    required this.label,
    super.key,
  });

  @override
  State<SlideToAdvance> createState() => _SlideToAdvanceState();
}

class _SlideToAdvanceState extends State<SlideToAdvance> with SingleTickerProviderStateMixin {
  double _dx = 0;
  bool _completed = false;
  late double _maxDx;

  void _onDragUpdate(DragUpdateDetails d) {
    if (_completed) return;
    setState(() {
      _dx = (_dx + d.delta.dx).clamp(0.0, _maxDx);
    });
  }

  void _onDragEnd(DragEndDetails _) {
    if (_completed) return;
    if (_dx >= _maxDx * 0.8) {
      setState(() {
        _completed = true;
        _dx = _maxDx;
      });
      widget.onSlideComplete();
    } else {
      setState(() {
        _dx = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullW = constraints.maxWidth;
        const knobSize = 56.0;
        _maxDx = max(0, fullW - knobSize - 8);

        return SizedBox(
          height: 64,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Track
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                  color: Colors.white.withOpacity(0.05),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              
              // Knob
              Positioned(
                left: 4 + _dx,
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
