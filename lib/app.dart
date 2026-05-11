import 'package:flutter/material.dart';
import 'presentation/routes/app_routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SERRMA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
