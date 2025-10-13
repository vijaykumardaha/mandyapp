import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';
import 'package:mandyapp/helpers/extensions/string.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/screens/selling_screen.dart';
import 'package:mandyapp/screens/ai_chat_screen.dart';
import 'package:mandyapp/screens/settings_screen.dart';

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
  final GlobalKey<SellingScreenState> _sellingScreenKey = GlobalKey<SellingScreenState>();

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    customTheme = AppTheme.customTheme;
    initialIndex = widget.activeTab;
  }
  
  List<Widget> get _screens => [
    SellingScreen(key: _sellingScreenKey),
    const AIChatScreen(),
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
        title: "Selling"),
    const TabItem(
        icon: Icons.receipt,
        activeIcon: Icons.receipt_outlined,
        title: "AI Chat"),
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
        appBar: AppBar(
          titleSpacing: 16,
          title: MyText.titleMedium(_getTitle(), fontWeight: 600),
          actions: initialIndex == 0 ? [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                _sellingScreenKey.currentState?.showCategoryFilterDialog();
              },
              tooltip: 'filter'.tr(),
            ),
          ] : null,
        ),
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

  String _getTitle() {
    switch (initialIndex) {
      case 0:
        return 'selling'.tr();
      case 1:
        return 'ai_chat'.tr();
      case 2:
        return 'settings'.tr();
      default:
        return 'my_mandy'.tr();
    }
  }
}
