
import 'package:electrition_bill/splah_screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ElectritionBillApp());
}

class ElectritionBillApp extends StatelessWidget {
  const ElectritionBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Durga Electricals',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CustomSplashScreen(), // Show splash first
    );
  }
}

// Utility to get the Downloads directory on Android, fallback to app docs on iOS/other
Future<Directory?> getDownloadsDirectory() async {
  if (Platform.isAndroid) {
    final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
    if (dirs != null && dirs.isNotEmpty) {
      return dirs.first;
    } else {
      // Fallback to /storage/emulated/0/Download if possible
      final dir = Directory('/storage/emulated/0/Download');
      if (await dir.exists()) return dir;
      try {
        await dir.create(recursive: true);
        return dir;
      } catch (_) {
        // Fallback to app-specific
        return await getExternalStorageDirectory();
      }
    }
  } else {
    return await getApplicationDocumentsDirectory();
  }
}

// Check if the latest bill file exists in Downloads
Future<bool> checkLatestBillFileExists(String extension) async {
  final downloadsDir = await getDownloadsDirectory();
  if (downloadsDir == null) {
    debugPrint('Error: getDownloadsDirectory() returned null');
    return false;
  }
  final files = downloadsDir.listSync().whereType<File>().where((f) => f.path.endsWith(extension)).toList();
  if (files.isEmpty) return false;
  files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return files.first.existsSync();
}



Future<File?> getLatestBillFile(String extension) async {
  final downloadsDir = await getDownloadsDirectory();
  if (downloadsDir == null) return null;
  final files = downloadsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith(extension))
      .toList();
  if (files.isEmpty) return null;
  files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return files.first;
}

// Add the custom splash screen widget
