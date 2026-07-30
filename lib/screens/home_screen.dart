import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandiapp/blocs/login/login_bloc.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/screens/billing_screen.dart';
import 'package:mandiapp/screens/home_tab_screen.dart';
import 'package:mandiapp/screens/selling_screen.dart';
import 'package:mandiapp/screens/settings_screen.dart';
import 'package:mandiapp/screens/bills_screen.dart';
import 'package:mandiapp/screens/customer_management_screen.dart';
import 'package:mandiapp/screens/reports_screen.dart';
import 'package:mandiapp/services/socket_service.dart';
import 'package:mandiapp/services/sync_service.dart';

class HomeScreen extends StatefulWidget {
  final int activeTab;
  const HomeScreen({super.key, required this.activeTab});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ThemeData theme;
  int initialIndex = 0;
  late CustomTheme customTheme;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    customTheme = AppTheme.customTheme;
    initialIndex = widget.activeTab;
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) async {
        final hasConnection = results.any((r) => r != ConnectivityResult.none);

        if (hasConnection && _wasOffline) {
          log('HomeScreen: connectivity restored, reconnecting websocket');
          if (!SocketService.instance.isConnected) {
            await SyncService.instance.connectAndSync();
          }
        }

        _wasOffline = !hasConnection;
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  List<Widget> get _screens => [
        const HomeTabScreen(),
        const BillingScreen(),
        const BillsScreen(),
        const SellingScreen(),
        const CustomerManagementScreen(),
        const ReportsScreen(),
        const SettingsScreen(),
      ];

  final _navLabels = const [
    "Home", "Billing", "Bills", "Selling",
    "Customers", "Reports", "Settings",
  ];

  final _unselectedIcons = const [
    Icons.home_outlined,
    Icons.shopping_cart_outlined,
    Icons.receipt_long_outlined,
    Icons.qr_code,
    Icons.people_outline,
    Icons.bar_chart_outlined,
    Icons.settings_outlined,
  ];

  final _selectedIcons = const [
    Icons.home,
    Icons.shopping_cart,
    Icons.receipt_long,
    Icons.qr_code,
    Icons.people,
    Icons.bar_chart,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LogoutSuccess) {
          context.go('/login');
        }
      },
      child: Scaffold(
        appBar: null,
        body: SafeArea(child: _screens[initialIndex]),
        bottomNavigationBar: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              currentIndex: initialIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: theme.cardTheme.surfaceTintColor,
              selectedItemColor: theme.primaryColor,
              unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
              showSelectedLabels: true,
              showUnselectedLabels: false,
              selectedFontSize: 13,
              unselectedFontSize: 13,
              elevation: 12,
              onTap: (int i) {
                setState(() {
                  initialIndex = i;
                });
              },
              items: List.generate(_navLabels.length, (i) => BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Icon(_unselectedIcons[i], size: 22),
                ),
                activeIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Icon(_selectedIcons[i], size: 26),
                ),
                label: _navLabels[i],
              )),
            )),
      ),
    );
  }
}
