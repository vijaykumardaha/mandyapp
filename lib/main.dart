/*
 * File : Main File
 * We are using our own package (FlutX) : https://pub.dev/packages/flutx
 * Version : 13
 * */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:krishimandi/blocs/bill_list/bill_list_bloc.dart';
import 'package:krishimandi/blocs/charge_types/charge_types_bloc.dart';
import 'package:krishimandi/blocs/customer/customer_bloc.dart';
import 'package:krishimandi/blocs/customer_payment/customer_payment_bloc.dart';
import 'package:krishimandi/blocs/login/login_bloc.dart';
import 'package:krishimandi/blocs/order/order_bloc.dart';
import 'package:krishimandi/blocs/order_expense/order_expense_bloc.dart';
import 'package:krishimandi/blocs/order_item/order_item_bloc.dart';
import 'package:krishimandi/blocs/order_payment/order_payment_bloc.dart';
import 'package:krishimandi/blocs/product/product_bloc.dart';
import 'package:krishimandi/blocs/reports/reports_bloc.dart';
import 'package:krishimandi/blocs/stock/stock_bloc.dart';
import 'package:krishimandi/blocs/user/user_bloc.dart';
import 'package:krishimandi/blocs/vegetable/vegetable_bloc.dart';
import 'package:krishimandi/dao/order_charge_dao.dart';
import 'package:krishimandi/dao/order_item_dao.dart';
import 'package:krishimandi/dao/order_payment_dao.dart';
import 'package:krishimandi/dao/report_dao.dart';
import 'package:krishimandi/helpers/theme/app_theme.dart';
import 'package:krishimandi/routes/app_routes.dart';
import 'package:krishimandi/utils/db_helper.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.init();

  // Initialize database
  await DBHelper.instance.database;

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        BlocProvider<StockBloc>(
          create: (context) => StockBloc(),
        ),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        routerConfig: AppRoutes.router,
      ),
    );
  }
}
