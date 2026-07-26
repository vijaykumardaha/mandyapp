import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/screens/billing_screen.dart';
import 'package:mandyapp/screens/home_tab_screen.dart';
import 'package:mandyapp/screens/selling_screen.dart';
import 'package:mandyapp/screens/settings_screen.dart';
import 'package:mandyapp/screens/customer_management_screen.dart';
import 'package:mandyapp/sync/socket_service.dart';
import 'package:mandyapp/sync/sync_service.dart';

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
        const SellingScreen(),
        const CustomerManagementScreen(),
        const SettingsScreen(),
      ];

  List<TabItem> tabItems = [
    const TabItem(
        icon: Icons.qr_code, activeIcon: Icons.qr_code_outlined, title: "Home"),
    const TabItem(
        icon: Icons.shopping_basket,
        activeIcon: Icons.shopping_basket_outlined,
        title: "Billing"),
    const TabItem(
        icon: Icons.point_of_sale,
        activeIcon: Icons.point_of_sale_outlined,
        title: "Selling"),
    const TabItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        title: "Customers"),
    const TabItem(
        icon: Icons.settings,
        activeIcon: Icons.settings_outlined,
        title: "Settings")
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
        body: _screens[initialIndex],
        bottomNavigationBar: ConvexAppBar(
            initialActiveIndex: initialIndex,
            backgroundColor: theme.cardTheme.surfaceTintColor,
            items: tabItems,
            style: TabStyle.fixed,
            onTap: (int i) {
              setState(() {
                initialIndex = i;
              });
            },
            elevation: 0),
      ),
    );
  }
}
