import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

class Info {
  static OverlayEntry? _currentEntry;

  static void _showTop(BuildContext context, String message,
      Color backgroundColor, Color textColor,
      {Duration duration = const Duration(seconds: 3)}) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopToast(
        message: message,
        backgroundColor: backgroundColor,
        textColor: textColor,
        duration: duration,
        onDismiss: () {
          entry.remove();
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void message(String message,
      {GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
      BuildContext? context,
      Duration? duration,
      SnackBarBehavior snackBarBehavior = SnackBarBehavior.floating}) {
    if (context != null) {
      _showTop(context, message, Colors.green, Colors.white,
          duration: duration ?? const Duration(seconds: 3));
    }
  }

  static void error(String message,
      {GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey,
      BuildContext? context,
      Duration? duration,
      SnackBarBehavior snackBarBehavior = SnackBarBehavior.floating}) {
    if (context != null) {
      _showTop(context, message, Colors.red, Colors.white,
          duration: duration ?? const Duration(seconds: 3));
    }
  }
}

class _TopToast extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopToast({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    _timer = Timer(widget.duration, () {
      _controller.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: widget.backgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: MyText(
              widget.message,
              color: widget.textColor,
            ),
          ),
        ),
      ),
    );
  }
}
