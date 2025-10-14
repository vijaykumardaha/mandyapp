import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/blocs/customer/customer_bloc.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:mandyapp/models/customer_model.dart';

// Initial screen that checks login status and redirects
class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger login check when screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncPhoneContacts();
      context.read<LoginBloc>().add(CheckLoginStatus());
    });
  }

  String extractLast10Digits(String phoneNumber) {
    return phoneNumber.substring(phoneNumber.length - 10);
  }

  void syncPhoneContacts() async {
    if (await FlutterContacts.requestPermission(readonly: true)) {
      final phoneContacts =
          await FlutterContacts.getContacts(withProperties: true);

      List<Customer> converted = phoneContacts
          .where((c) => c.phones.isNotEmpty)
          .map((c) => Customer(
              name: c.displayName,
              phone: extractLast10Digits(c.phones.first.normalizedNumber)))
          .toList();

      context.read<CustomerBloc>().add(SyncCustomer(customers: converted));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          // User is logged in, redirect to home
          context.go('/home');
        } else if (state is CheckingFailed) {
          // User is not logged in, redirect to login
          context.go('/login');
        }
      },
      builder: (context, state) {
        return const Scaffold(
          body: Center(
            child: Text('Checking login status...'),
          ),
        );
      },
    );
  }
}
