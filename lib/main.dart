import 'package:electrition_bill/routing/bottomnavigationbar.dart';
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
      title: 'DURGA ELECTRICALS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Bottomnavigation(), // Use Bottomnavigation as the home page
    );
  }
}

// Add a function to check if the latest bill file exists in external storage
Future<bool> checkLatestBillFileExists(String extension) async {
  final output = await getExternalStorageDirectory();
  if (output == null) {
    debugPrint('Error: getExternalStorageDirectory() returned null');
    return false;
  }
  final dir = Directory(output.path);
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith(extension)).toList();
  if (files.isEmpty) return false;
  files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return files.first.existsSync();
}



Future<File?> getLatestBillFile(String extension) async {
  Directory? downloadsDir;
  if (Platform.isAndroid) {
    final dirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
    if (dirs != null && dirs.isNotEmpty) {
      downloadsDir = dirs.first;
    } else {
      downloadsDir = await getExternalStorageDirectory();
    }
  } else {
    downloadsDir = await getApplicationDocumentsDirectory();
  }
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



