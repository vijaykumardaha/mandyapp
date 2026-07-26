import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';
import 'package:mandyapp/controllers/login_controller.dart';
import 'package:mandyapp/services/sync_service.dart';

import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/widgets/common/my_button.dart';
import 'package:mandyapp/widgets/common/my_spacing.dart';
import 'package:mandyapp/widgets/common/my_text.dart';
import 'package:flutter/material.dart';
import 'package:mandyapp/utils/info_controller.dart';
import 'package:mandyapp/widgets/auth/mobile_field.dart';
import 'package:mandyapp/widgets/auth/password_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late ThemeData theme;
  late LoginController controller;
  late OutlineInputBorder outlineInputBorder;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    controller = LoginController();
    outlineInputBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(
        color: theme.dividerColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) async {
          if (state is LoginFailure) {
            Info.error(state.error, context: context);
          }

          if (state is LoginSuccess) {
            await SyncService.instance.connectAndSync();
            context.go('/home');
          }
        },
        builder: (context, state) {
          if (state is LoginLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: MySpacing.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  MySpacing.height(60),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MyText.headlineMedium(
                      "Sign In",
                      fontWeight: 700,
                    ),
                  ),
                  MySpacing.height(8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MyText.bodyMedium(
                      "Welcome back! Please login to continue",
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  MySpacing.height(32),
                  Form(
                    key: controller.formKey,
                    child: Column(
                      children: [
                        AuthMobileField(
                          controller: controller.mobileController,
                          outlineInputBorder: outlineInputBorder,
                          theme: theme,
                          validator: controller.validateMobileNumber,
                        ),
                        MySpacing.height(20),
                        AuthPasswordField(
                          controller: controller.passwordController,
                          outlineInputBorder: outlineInputBorder,
                          theme: theme,
                          validator: controller.validatePassword,
                        ),
                      ],
                    ),
                  ),
                  MySpacing.height(24),
                  MyButton.block(
                    padding: MySpacing.y(20),
                    onPressed: () {
                      if (controller.formKey.currentState!.validate()) {
                        context.read<LoginBloc>().add(
                              LoginSubmit(
                                mobile: controller.mobileController.text,
                                password: controller.passwordController.text,
                              ),
                            );
                      }
                    },
                    backgroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    borderRadiusAll: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MyText.bodySmall("Sign In".toUpperCase(),
                            fontWeight: 700,
                            color: theme.colorScheme.onPrimary,
                            letterSpacing: 0.5),
                      ],
                    ),
                  ),
                  MySpacing.height(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MyText.bodyMedium(
                        "Don't have an account? ",
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
                      ),
                      InkWell(
                        onTap: () => context.go('/signup'),
                        child: MyText.bodyMedium(
                          "Sign Up",
                          fontWeight: 600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
