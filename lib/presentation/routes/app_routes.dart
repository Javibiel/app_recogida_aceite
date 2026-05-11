import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/client/home_client_screen.dart';
import '../screens/operator/home_operator_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String clientHome = '/client';
  static const String operatorHome = '/operator';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    clientHome: (context) => const HomeClientScreen(),
    operatorHome: (context) => const HomeOperatorScreen(),
  };
}
