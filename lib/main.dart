/*
 * File : Main File
 * We are using our own package (FlutX) : https://pub.dev/packages/flutx
 * Version : 13
 * */

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:mandiapp/blocs/bill_list/bill_list_bloc.dart';
import 'package:mandiapp/blocs/order/order_bloc.dart';
import 'package:mandiapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandiapp/blocs/customer/customer_bloc.dart';
import 'package:mandiapp/blocs/customer_payment/customer_payment_bloc.dart';
import 'package:mandiapp/blocs/order_item/order_item_bloc.dart';
import 'package:mandiapp/blocs/login/login_bloc.dart';
import 'package:mandiapp/blocs/product/product_bloc.dart';
import 'package:mandiapp/blocs/reports/reports_bloc.dart';
import 'package:mandiapp/blocs/user/user_bloc.dart';
import 'package:mandiapp/blocs/order_payment/order_payment_bloc.dart';
import 'package:mandiapp/blocs/order_expense/order_expense_bloc.dart';
import 'package:mandiapp/blocs/vegetable/vegetable_bloc.dart';
import 'package:mandiapp/dao/order_charge_dao.dart';
import 'package:mandiapp/dao/order_payment_dao.dart';
import 'package:mandiapp/dao/order_item_dao.dart';
import 'package:mandiapp/dao/report_dao.dart';
import 'package:mandiapp/helpers/localizations/app_localization_delegate.dart';
import 'package:mandiapp/utils/db_helper.dart';
import 'package:mandiapp/helpers/localizations/language.dart';
import 'package:mandiapp/helpers/theme/app_notifier.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.init();

  // Initialize language
  await Language.init();

  // Initialize database
  await DBHelper.instance.database;

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await FlutterContacts.requestPermission(readonly: true);
  await requestBluetoothPermissions();

  runApp(ChangeNotifierProvider<AppNotifier>(
    create: (context) => AppNotifier(),
    child: MyApp(),
  ));
}

Future<void> requestBluetoothPermissions() async {
  final Map<Permission, PermissionStatus> statuses = await <Permission>[
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ].request();

  final bool granted = statuses[Permission.bluetoothScan]?.isGranted == true &&
      statuses[Permission.bluetoothConnect]?.isGranted == true;

  if (!granted) {
    debugPrint('Bluetooth permissions denied: $statuses');
  } else {
    debugPrint('Bluetooth permissions granted');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          BlocProvider<LoginBloc>(
            create: (context) => LoginBloc(),
          ),
          BlocProvider<UserBloc>(
            create: (context) => UserBloc(),
          ),
          BlocProvider<ProductBloc>(
            create: (context) => ProductBloc(),
          ),
          BlocProvider<ChargeTypesBloc>(
            create: (context) => ChargeTypesBloc(),
          ),
          BlocProvider<OrderBloc>(
            create: (context) => OrderBloc(),
          ),
                    BlocProvider<CustomerBloc>(
            create: (context) => CustomerBloc(),
          ),
          BlocProvider<CustomerPaymentBloc>(
            create: (context) => CustomerPaymentBloc(),
          ),
          BlocProvider<VegetableBloc>(
            create: (context) => VegetableBloc(),
          ),
          BlocProvider<OrderPaymentBloc>(
            create: (context) => OrderPaymentBloc(),
          ),
          BlocProvider<OrderExpenseBloc>(
            create: (context) => OrderExpenseBloc(),
          ),
          BlocProvider<OrderItemBloc>(
            create: (context) => OrderItemBloc(),
          ),
          BlocProvider<ReportsBloc>(
            create: (context) => ReportsBloc(reportDAO: ReportDAO()),
          ),
          BlocProvider<BillListBloc>(
            create: (context) => BillListBloc(
              orderBloc: context.read<OrderBloc>(),
              paymentBloc: context.read<OrderPaymentBloc>(),
              chargeTypesBloc: context.read<ChargeTypesBloc>(),
              orderChargeDAO: OrderChargeDAO(),
              orderPaymentDAO: OrderPaymentDAO(),
              orderItemDAO: OrderItemDAO(),
            ),
          ),
        ],
        child: Consumer<AppNotifier>(
            builder: (BuildContext context, AppNotifier value, Widget? child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            // home: const SplashScreen(),
            builder: (context, child) {
              return Directionality(
                textDirection: AppTheme.textDirection,
                child: child ?? Container(),
              );
            },
            localizationsDelegates: [
              AppLocalizationsDelegate(context),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: Language.getLocales(),
            routerConfig: AppRoutes.router,
          );
        }));
  }
}
