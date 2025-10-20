import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_bottom_navigation_bar.dart';
import 'package:mandyapp/models/customer_model.dart';
import 'package:mandyapp/screens/ai_chat_screen.dart';
import 'package:mandyapp/screens/reports_screen.dart';
import 'package:mandyapp/screens/selling_screen.dart';
import 'package:mandyapp/screens/settings_screen.dart';
import 'package:mandyapp/screens/bill_list_screen.dart';

class HomeScreen extends StatefulWidget {
  final int activeTab;
  const HomeScreen({super.key, required this.activeTab});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ThemeData theme;
  int initialIndex = 0;

  MyBottomNavigationBarType bottomNavigationBarType =
      MyBottomNavigationBarType.normal;
  Axis labelDirection = Axis.horizontal;
  bool showLabel = false, showActiveLabel = true;
  late CustomTheme customTheme;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    customTheme = AppTheme.customTheme;
    initialIndex = widget.activeTab;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCustomersSeeded();
    });
  }

  List<Widget> get _screens => [
        const AIChatScreen(),
        const ReportsScreen(),
        const SellingScreen(),
        const BillListScreen(),
        const SettingsScreen(),
      ];

  @override
  void dispose() {
    super.dispose();
  }

  List<TabItem> tabItems = [
    const TabItem(
        icon: Icons.qr_code,
        activeIcon: Icons.qr_code_outlined,
        title: "AI Chat"),
    const TabItem(
        icon: Icons.bar_chart,
        activeIcon: Icons.bar_chart_outlined,
        title: "Reports"),
    const TabItem(
        icon: Icons.point_of_sale,
        activeIcon: Icons.point_of_sale_outlined,
        title: "Selling"),
    const TabItem(
        icon: Icons.receipt_long,
        activeIcon: Icons.receipt_outlined,
        title: "Bills"),
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

  String _extractLast10Digits(String phoneNumber) {
    if (phoneNumber.length < 10) {
      return phoneNumber;
    }
    return phoneNumber.substring(phoneNumber.length - 10);
  }

  Future<void> _ensureCustomersSeeded() async {
    final customerBloc = context.read<CustomerBloc>();
    final customerDao = customerBloc.contactDAO;
    final existingCount = await customerDao.getCustomerCount();
    if (existingCount > 1) {
      return;
    }

    await _syncPhoneContacts();
  }

  Future<void> _syncPhoneContacts() async {
    final hasPermission = await FlutterContacts.requestPermission(readonly: true);
    if (!hasPermission) {
      return;
    }

    final phoneContacts = await FlutterContacts.getContacts(withProperties: true);

    final List<Customer> converted = phoneContacts
        .where((c) => c.phones.isNotEmpty && c.phones.first.normalizedNumber.isNotEmpty)
        .map((c) => Customer(
              name: c.displayName,
              phone: _extractLast10Digits(c.phones.first.normalizedNumber),
            ))
        .toList();

    context.read<CustomerBloc>().add(SyncCustomer(customers: converted));
  }
}
