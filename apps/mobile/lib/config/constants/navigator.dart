import 'package:flutter/material.dart';

/// 🔹 Reusable Page Transition Function
Future navigateTo(BuildContext context, Widget page) {
  return Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0), // right to left
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.ease,
        )),
        child: child,
      ),
    ),
  );
}
