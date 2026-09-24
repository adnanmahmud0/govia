import 'package:flutter/material.dart';

/// ================= GLOBAL ANIMATED DIALOG ================= ///
class AppDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,

    /// ================= CONFIG ================= ///
    bool barrierDismissible = true,
    String barrierLabel = 'Dismiss',
    Color barrierColor = const Color.fromRGBO(0, 0, 0, 0.4),
    Duration duration = const Duration(milliseconds: 300),

    /// ================= ANIMATION TYPE ================= ///
    DialogAnimation animation = DialogAnimation.slideUp,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      transitionDuration: duration,

      /// ================= PAGE ================= ///
      pageBuilder: (_, _, _) => child,

      /// ================= TRANSITION ================= ///
      transitionBuilder: (_, animationController, _, child) {
        switch (animation) {
          case DialogAnimation.fade:
            return FadeTransition(
              opacity: animationController,
              child: child,
            );

          case DialogAnimation.scale:
            return ScaleTransition(
              scale: CurvedAnimation(
                parent: animationController,
                curve: Curves.easeOutBack,
              ),
              child: FadeTransition(
                opacity: animationController,
                child: child,
              ),
            );

          case DialogAnimation.slideLeft:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(_curve(animationController)),
              child: child,
            );

          case DialogAnimation.slideRight:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(_curve(animationController)),
              child: child,
            );

          case DialogAnimation.slideUp:
          return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(_curve(animationController)),
              child: FadeTransition(
                opacity: animationController,
                child: child,
              ),
            );
        }
      },
    );
  }

  static CurvedAnimation _curve(Animation<double> animation) {
    return CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
  }
}

/// ================= ANIMATION TYPES ================= ///
enum DialogAnimation {
  slideUp,
  slideLeft,
  slideRight,
  fade,
  scale,
}
