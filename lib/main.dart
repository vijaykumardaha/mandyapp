/*
 * File : Main File
 * We are using our own package (FlutX) : https://pub.dev/packages/flutx
 * Version : 13
 * */

import 'package:another_telephony/telephony.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:mandyapp/blocs/bill_list/bill_list_bloc.dart';
import 'package:mandyapp/blocs/order/order_bloc.dart';
import 'package:mandyapp/blocs/charge_types/charge_types_bloc.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/blocs/customer_payment/customer_payment_bloc.dart';
import 'package:mandyapp/blocs/order_item/order_item_bloc.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';
import 'package:mandyapp/blocs/product/product_bloc.dart';
import 'package:mandyapp/blocs/reports/reports_bloc.dart';
import 'package:mandyapp/blocs/user/user_bloc.dart';
import 'package:mandyapp/blocs/order_payment/order_payment_bloc.dart';
import 'package:mandyapp/blocs/order_expense/order_expense_bloc.dart';
import 'package:mandyapp/blocs/vegetable/vegetable_bloc.dart';
import 'package:mandyapp/dao/order_charge_dao.dart';
import 'package:mandyapp/dao/order_payment_dao.dart';
import 'package:mandyapp/dao/order_item_dao.dart';
import 'package:mandyapp/dao/report_dao.dart';
import 'package:mandyapp/helpers/localizations/app_localization_delegate.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:mandyapp/helpers/localizations/language.dart';
import 'package:mandyapp/helpers/theme/app_notifier.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/routes/app_routes.dart';
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

  // asking sms permission for sending entry sms
  final Telephony telephony = Telephony.instance;
  await telephony.requestPhoneAndSmsPermissions;

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
