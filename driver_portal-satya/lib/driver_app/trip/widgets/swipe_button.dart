import 'package:flutter/material.dart';

import 'dart:async';

class SwipeButton extends StatefulWidget {
  final String text;
  final FutureOr<bool> Function() onSwipe;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final bool isActive;

  const SwipeButton({
    super.key,
    required this.text,
    required this.onSwipe,
    this.backgroundColor = Colors.orange,
    this.textColor = Colors.black,
    this.icon = Icons.arrow_forward,
    this.isActive = true,
  });

  @override
  State<SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<SwipeButton> {
  double _position = 0.0;
  final double _buttonSize = 52.0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.isActive ? widget.backgroundColor : Colors.grey;
    final effectiveTextColor = widget.isActive ? widget.textColor : Colors.grey.shade600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxPosition = constraints.maxWidth - _buttonSize - 8;

        return Container(
          height: _buttonSize + 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(_buttonSize),
            border: Border.all(color: effectiveColor.withValues(alpha: 0.2), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Filled Background Effect
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _position + (_buttonSize / 2) + 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: effectiveColor,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(_buttonSize),
                      right: Radius.circular(_position > (maxPosition / 2) ? _buttonSize : 0),
                    ),
                  ),
                ),
              ),

              // Background Text
              Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: _position > (maxPosition / 2) 
                        ? (effectiveTextColor == Colors.black ? Colors.white70 : effectiveTextColor.withValues(alpha: 0.7))
                        : effectiveColor.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),

              // Swipable Icon
              Positioned(
                left: _position + 4,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (!widget.isActive || _completed) return;
                    setState(() {
                      _position += details.delta.dx;
                      if (_position < 0) _position = 0;
                      if (_position > maxPosition) _position = maxPosition;
                    });
                  },
                  onHorizontalDragEnd: (details) async {
                    if (!widget.isActive || _completed) return;
                    if (_position > maxPosition * 0.7) {
                      setState(() {
                        _position = maxPosition;
                        _completed = true;
                      });
                      final result = await widget.onSwipe();
                      if (result == false) {
                        if (mounted) {
                          setState(() {
                            _position = 0;
                            _completed = false;
                          });
                        }
                      }
                    } else {
                      setState(() {
                        _position = 0;
                      });
                    }
                  },
                  child: Container(
                    width: _buttonSize,
                    height: _buttonSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: effectiveColor,
                      size: 28,
                    ),
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


