import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mandiapp/blocs/login/login_bloc.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/services/socket_service.dart';
import 'package:mandiapp/services/sync_service.dart';
import 'package:mandiapp/utils/app_helper.dart';
import 'package:mandiapp/widgets/common/my_text.dart';
import 'package:mandiapp/widgets/common/my_text_style.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  late ThemeData theme;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  String _userName = 'Customer';

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    _startConnectivityListener();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final userData = await AppHelper.getPreferences('user');
    if (userData != null && mounted) {
      final user = userData as Map<String, dynamic>;
      setState(() => _userName = user['name'] ?? 'Customer');
    }
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) async {
        final hasConnection = results.any((r) => r != ConnectivityResult.none);

        if (hasConnection && _wasOffline) {
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

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 20),
      child: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: kToolbarHeight + 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText.titleLarge(_userName, fontWeight: 700),
            MyText.bodyMedium(
              _dateFormat.format(DateTime.now()),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
        titleTextStyle: MyTextStyle.bodyMedium(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LogoutSuccess) {
          context.go('/login');
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Center(
            child: MyText.bodyLarge(
              'Customer Home',
              fontWeight: 600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
