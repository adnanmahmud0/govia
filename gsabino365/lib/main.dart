import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gsabino365/app.dart';
import 'package:gsabino365/core/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env asset
  await dotenv.load(fileName: '.env');

  // Initialize FCM service (graceful if credentials not yet added)
  FcmService().initialize();

  runApp(const MyApp());
}


