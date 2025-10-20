import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<LoginBloc>().add(CheckLoginStatus());
    });
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
