// lib/widgets/payment_lock_overlay.dart
import 'dart:ui';

import 'package:flutter/material.dart';

class PaymentLockOverlay {
  static OverlayEntry? _overlayEntry;
  
  static void show({
    required BuildContext context,
    required Widget content,
    bool blurBackground = true,
    double blurSigma = 10.0,
    Color backgroundColor = Colors.black54,
    bool dismissible = false,
  }) {
    // Retirer l'overlay existant s'il y en a un
    hide();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _PaymentLockOverlayWidget(
        content: content,
        blurBackground: blurBackground,
        blurSigma: blurSigma,
        backgroundColor: backgroundColor,
        dismissible: dismissible,
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  static void hide() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }
}

class _PaymentLockOverlayWidget extends StatelessWidget {
  final Widget content;
  final bool blurBackground;
  final double blurSigma;
  final Color backgroundColor;
  final bool dismissible;
  
  const _PaymentLockOverlayWidget({
    required this.content,
    required this.blurBackground,
    required this.blurSigma,
    required this.backgroundColor,
    required this.dismissible,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: dismissible ? () => PaymentLockOverlay.hide() : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fond flouté ou semi-transparent
            if (blurBackground)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(color: backgroundColor),
              )
            else
              Container(color: backgroundColor),
            
            // Contenu centré
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: content,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}