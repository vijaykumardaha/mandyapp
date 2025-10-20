import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/screens/about_screen.dart';
import 'package:mandyapp/screens/home_screen.dart';
import 'package:mandyapp/screens/login_screen.dart';
import 'package:mandyapp/screens/profile_screen.dart';
import 'package:mandyapp/screens/signup_screen.dart';
import 'package:mandyapp/screens/charges_screen.dart';
import 'package:mandyapp/screens/initial_screen.dart';
import 'package:mandyapp/screens/product_list_screen.dart';
import 'package:mandyapp/screens/privacy_policy_screen.dart';
import 'package:mandyapp/screens/printer_settings_screen.dart';
import 'package:mandyapp/screens/terms_conditions_screen.dart';
import 'package:mandyapp/screens/theme_settings_screen.dart';
import 'package:mandyapp/screens/language_settings_screen.dart';
import 'package:mandyapp/screens/notification_settings_screen.dart';
import 'package:mandyapp/screens/customer_management_screen.dart';
import 'package:mandyapp/screens/stock_screen.dart';
import 'package:mandyapp/screens/bill_list_screen.dart';

class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) {
          return const InitialScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) {
          return const SignupScreen();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          return const HomeScreen(
            activeTab: 0,
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          return const ProfileScreen();
        },
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) {
          return const AboutScreen();
        },
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) {
          return const PrivacyPolicyScreen();
        },
      ),
      GoRoute(
        path: '/terms-conditions',
        builder: (context, state) {
          return const TermsConditionsScreen();
        },
      ),
      GoRoute(
        path: '/theme-settings',
        builder: (context, state) {
          return const ThemeSettingsScreen();
        },
      ),
      GoRoute(
        path: '/language-settings',
        builder: (context, state) {
          return const LanguageSettingsScreen();
        },
      ),
      GoRoute(
        path: '/notification-settings',
        builder: (context, state) {
          return const NotificationSettingsScreen();
        },
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) {
          return const ProductListScreen();
        },
      ),
      GoRoute(
        path: '/charges',
        builder: (context, state) {
          return const ChargesScreen();
        },
      ),
      GoRoute(
        path: '/printer-settings',
        builder: (context, state) {
          return const PrinterSettingsScreen();
        },
      ),
      GoRoute(
        path: '/customers',
        builder: (context, state) {
          return const CustomerManagementScreen();
        },
      ),
      GoRoute(
        path: '/stock',
        builder: (context, state) {
          return const StockScreen();
        },
      ),
      GoRoute(
        path: '/bills',
        builder: (context, state) {
          return const BillListScreen();
        },
      ),
    ],
    errorBuilder: (context, state) => const Text('Page Not Found'),
  );
}
