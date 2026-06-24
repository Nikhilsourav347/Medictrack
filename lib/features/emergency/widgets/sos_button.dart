import 'package:flutter/material.dart';

class SosButton extends StatefulWidget {
  /// Called when the user has held for the full [holdDuration]
  final VoidCallback onTriggered;
  final Duration holdDuration;

  const SosButton({
    super.key,
    required this.onTriggered,
    this.holdDuration = const Duration(seconds: 3),
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _holding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reset();
          setState(() => _holding = false);
          widget.onTriggered();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _holding = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) => _cancel();
  void _onTapCancel() => _cancel();

  void _cancel() {
    if (!_controller.isCompleted) {
      _controller.reset();
      setState(() => _holding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = _controller.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing outer ring
                  if (_holding)
                    ...List.generate(2, (i) {
                      final scale = 1.0 + (progress * 0.3) + (i * 0.15);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE53935)
                                  .withValues(alpha: 0.3 - (i * 0.1)),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }),

                  // Progress arc ring
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFE53935)),
                    ),
                  ),

                  // Main button
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: _holding
                            ? [
                                const Color(0xFFFF6659),
                                const Color(0xFFE53935),
                                const Color(0xFFB71C1C),
                              ]
                            : [
                                const Color(0xFFEF5350),
                                const Color(0xFFE53935),
                                const Color(0xFFC62828),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935)
                              .withValues(alpha: _holding ? 0.6 : 0.4),
                          blurRadius: _holding ? 30 : 20,
                          spreadRadius: _holding ? 8 : 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: _holding ? 44 : 40,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Text(
            _holding
                ? 'Calling in ${(widget.holdDuration.inSeconds * (1 - _controller.value)).ceil()}s...'
                : 'Hold 3 seconds to call',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _holding
                  ? const Color(0xFFE53935)
                  : Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }
}
