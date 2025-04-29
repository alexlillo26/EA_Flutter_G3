import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';


final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => LoginScreen(),
  '/register': (context) => RegisterScreen(),
  '/home': (context) => HomeScreen(),
  '/profile': (context) => ProfileScreen(),
};
