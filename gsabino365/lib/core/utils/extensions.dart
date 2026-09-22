import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ===================== EXTENSIONS =====================
/// Reusable extension methods on core Dart/Flutter types.

// ──────────────────── STRING ────────────────────

extension StringExtension on String {
  /// Capitalize first letter: "hello" → "Hello"
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word: "hello world" → "Hello World"
  String toTitleCase() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Validate email format
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Validate phone number
  bool get isValidPhone {
    return RegExp(r'^\+?[\d\s-]{10,15}$').hasMatch(this);
  }

  /// Truncate with ellipsis: "Hello World".truncate(5) → "Hello..."
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  /// Parse to int safely
  int? toIntOrNull() => int.tryParse(this);

  /// Parse to double safely
  double? toDoubleOrNull() => double.tryParse(this);
}

// ──────────────────── DATETIME ────────────────────

extension DateTimeExtension on DateTime {
  /// "27/04/2026"
  String toFormattedDate() {
    return DateFormat('dd/MM/yyyy').format(this);
  }

  /// "27 Apr, 2026"
  String toReadableDate() {
    return DateFormat('dd MMM, yyyy').format(this);
  }

  /// "12:30 PM"
  String toFormattedTime() {
    return DateFormat('hh:mm a').format(this);
  }

  /// "27 Apr, 2026 at 12:30 PM"
  String toFullDateTime() {
    return '${DateFormat('dd MMM, yyyy').format(this)} at ${DateFormat('hh:mm a').format(this)}';
  }

  /// Time ago: "2 hours ago", "Just now"
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}

// ──────────────────── BUILD CONTEXT ────────────────────

extension ContextExtension on BuildContext {
  // Screen dimensions
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;

  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // Navigation shortcuts
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  Future<T?> pushNamed<T>(String route, {Object? arguments}) =>
      Navigator.of(this).pushNamed<T>(route, arguments: arguments);

  // Snackbar shortcut
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade100 : Colors.green.shade100,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ──────────────────── NUM ────────────────────

extension NumExtension on num {
  /// Horizontal spacing: 16.horizontalSpace
  SizedBox get horizontalSpace => SizedBox(width: toDouble());

  /// Vertical spacing: 16.verticalSpace
  SizedBox get verticalSpace => SizedBox(height: toDouble());

  /// Format as currency: 1234.56.toCurrency() → "$1,234.56"
  String toCurrency({String symbol = '\$', int decimals = 2}) {
    return '$symbol${toStringAsFixed(decimals).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}';
  }
}
