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
import 'package:mandyapp/screens/reports_screen.dart';

class HomeScreen extends StatefulWidget {
  final int activeTab;
  const HomeScreen({super.key, required this.activeTab});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ThemeData theme;
  int initialIndex = 0;

  // Bottom nav config removed with sync code
  late CustomTheme customTheme;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    customTheme = AppTheme.customTheme;
    initialIndex = widget.activeTab;
  }

  List<Widget> get _screens => [
        const HomeTabScreen(),
        const BillingScreen(),
        const SellingScreen(),
        const ReportsScreen(),
        const SettingsScreen(),
      ];

  @override
  void dispose() {
    super.dispose();
  }

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
        icon: Icons.receipt_long,
        activeIcon: Icons.receipt_outlined,
        title: "Reports"),
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
