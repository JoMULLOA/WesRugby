import 'package:flutter/material.dart';

/// Widget que envuelve otro widget y produce un efecto de pulse efímero
/// al tocarlo, sin mantener una selección permanente.
/// 
/// El efecto aparece durante 250-300ms y luego desaparece automáticamente.
/// Útil para indicar interacción táctil sin estado persistente.
class PulseOnTap extends StatefulWidget {
  /// El widget hijo que recibirá el efecto pulse
  final Widget child;
  
  /// Duración del efecto pulse en milisegundos (por defecto 280ms)
  final int duration;
  
  /// Color del efecto pulse (por defecto blanco semi-transparente)
  final Color pulseColor;
  
  /// Callback opcional cuando se toca el widget
  final VoidCallback? onTap;
  
  /// Radio del borde del efecto (por defecto 14)
  final double borderRadius;

  const PulseOnTap({
    super.key,
    required this.child,
    this.duration = 280,
    this.pulseColor = const Color(0x33FFFFFF),
    this.onTap,
    this.borderRadius = 14,
  });

  @override
  State<PulseOnTap> createState() => _PulseOnTapState();
}

class _PulseOnTapState extends State<PulseOnTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isPulsing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.duration),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isPulsing = false;
          });
          _controller.reset();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerPulse() {
    if (!_isPulsing) {
      setState(() {
        _isPulsing = true;
      });
      _controller.forward();
      
      // Ejecutar el callback si existe
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _triggerPulse,
      child: Semantics(
        button: true,
        enabled: true,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              decoration: _isPulsing
                  ? BoxDecoration(
                      color: widget.pulseColor.withOpacity(
                        _animation.value * widget.pulseColor.opacity,
                      ),
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    )
                  : null,
              child: widget.child,
            );
          },
        ),
      ),
    );
  }
}
