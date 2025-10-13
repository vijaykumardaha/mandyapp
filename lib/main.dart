/*
* File : Main File
* We are using our own package (FlutX) : https://pub.dev/packages/flutx
* Version : 13
* */

import 'package:another_telephony/telephony.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:mandyapp/blocs/cart/cart_bloc.dart';
import 'package:mandyapp/blocs/checkout/checkout_bloc.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';
import 'package:mandyapp/blocs/user/user_bloc.dart';
import 'package:mandyapp/blocs/product/product_bloc.dart';
import 'package:mandyapp/blocs/category/category_bloc.dart';
import 'package:mandyapp/helpers/localizations/app_localization_delegate.dart';
import 'package:mandyapp/utils/db_helper.dart';
import 'package:mandyapp/helpers/localizations/language.dart';
import 'package:mandyapp/helpers/theme/app_notifier.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  // asking sms permission for sending entry sms
  final Telephony telephony = Telephony.instance;
  await telephony.requestPhoneAndSmsPermissions;

  runApp(ChangeNotifierProvider<AppNotifier>(
    create: (context) => AppNotifier(),
    child: MyApp(),
  ));
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
          BlocProvider<CategoryBloc>(
            create: (context) => CategoryBloc(),
          ),
          BlocProvider<CartBloc>(
            create: (context) => CartBloc(),
          ),
          BlocProvider<CheckoutBloc>(
            create: (context) => CheckoutBloc(),
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

