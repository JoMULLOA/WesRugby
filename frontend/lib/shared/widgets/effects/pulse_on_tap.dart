import 'package:flutter/material.dart';

/// Simple wrapper that keeps the API used in the app while delegating gestures
/// to the provided child (Tab, Button, etc.). Pulse animation can be added in
/// the future; for now we just ensure compatibility and avoid breaking taps.
class PulseOnTap extends StatelessWidget {
  final Widget child;
  final int duration;
  final Color pulseColor;

  const PulseOnTap({
    super.key,
    required this.child,
    this.duration = 200,
    this.pulseColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
