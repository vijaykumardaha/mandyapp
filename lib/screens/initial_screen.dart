import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';
import 'package:mandyapp/sync/phoenix_socket_service.dart';
import 'package:mandyapp/sync/sync_service.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<LoginBloc>().add(CheckLoginStatus());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) async {
        if (state is LoginSuccess) {
          await PhoenixSocketService.instance.connect();
          SyncService.instance.startListening();
          context.go('/home');
        } else if (state is CheckingFailed) {
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
