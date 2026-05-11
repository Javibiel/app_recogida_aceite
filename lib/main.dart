import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/firestore_database.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  unawaited(_seedInitialData());
  runApp(const MyApp());
}

Future<void> _seedInitialData() async {
  try {
    await FirestoreDatabase().seedInitialData();
  } catch (error) {
    debugPrint('No se pudieron cargar los datos iniciales: $error');
  }
}
