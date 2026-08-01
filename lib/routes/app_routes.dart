import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mandiapp/screens/bill_details_screen.dart';
import 'package:mandiapp/screens/bills_screen.dart';
import 'package:mandiapp/screens/charges_screen.dart';
import 'package:mandiapp/screens/customer_home_screen.dart';
import 'package:mandiapp/screens/customer_management_screen.dart';
import 'package:mandiapp/screens/home_screen.dart';
import 'package:mandiapp/screens/initial_screen.dart';
import 'package:mandiapp/screens/login_screen.dart';
import 'package:mandiapp/screens/printer_settings_screen.dart';
import 'package:mandiapp/screens/privacy_policy_screen.dart';
import 'package:mandiapp/screens/product_list_screen.dart';
import 'package:mandiapp/screens/profile_screen.dart';
import 'package:mandiapp/screens/reports_screen.dart';
import 'package:mandiapp/screens/signup_introduction_screen.dart';
import 'package:mandiapp/screens/signup_screen.dart';
import 'package:mandiapp/screens/staff_screen.dart';
import 'package:mandiapp/screens/stock_screen.dart';
import 'package:mandiapp/screens/terms_conditions_screen.dart';

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
        path: '/customer-home',
        builder: (context, state) {
          return const CustomerHomeScreen();
        },
      ),
      GoRoute(
        path: '/signup-intro',
        builder: (context, state) {
          return const SignupIntroductionScreen();
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
        path: '/products',
        builder: (context, state) {
          return const ProductListScreen();
        },
      ),
      GoRoute(
        path: '/charges',
        builder: (context, state) {
          return const ChargeTypesScreen();
        },
      ),
      GoRoute(
        path: '/staff',
        builder: (context, state) {
          return const StaffScreen();
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
        path: '/bills',
        builder: (context, state) {
          return const ReportsScreen();
        },
      ),
      GoRoute(
        path: '/search-bills',
        builder: (context, state) {
          return const BillsScreen();
        },
      ),
      GoRoute(
        path: '/bill-details/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return BillDetailsScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/stock',
        builder: (context, state) {
          return const StockScreen();
        },
      ),
    ],
    errorBuilder: (context, state) => const Text('Page Not Found'),
  );
}
