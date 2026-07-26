import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';
import 'package:mandyapp/controllers/signup_controller.dart';
import 'package:mandyapp/sync/sync_service.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_button.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/utils/info_controller.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:mandyapp/widgets/auth/name_field.dart';
import 'package:mandyapp/widgets/auth/mobile_field.dart';
import 'package:mandyapp/widgets/auth/password_field.dart';
import 'package:mandyapp/widgets/auth/confirm_password_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late ThemeData theme;
  late SignupController controller;
  late OutlineInputBorder outlineInputBorder;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    controller = SignupController();
    outlineInputBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      borderSide: BorderSide(
        color: theme.dividerColor,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
                  MySpacing.height(40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MyText.headlineMedium(
                      "Create Account",
                      fontWeight: 700,
                    ),
                  ),
                  MySpacing.height(8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MyText.bodyMedium(
                      "Sign up to get started",
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  MySpacing.height(32),
                  signupForm(),
                  MySpacing.height(24),
                  MyButton.block(
                    padding: MySpacing.y(20),
                    onPressed: () {
                      if (controller.formKey.currentState!.validate()) {
                        context.read<LoginBloc>().add(
                              RegisterUser(
                                name: controller.nameController.text,
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
                        MyText.bodySmall(
                          "Sign Up".toUpperCase(),
                          fontWeight: 700,
                          color: theme.colorScheme.onPrimary,
                          letterSpacing: 0.5,
                        ),
                        MySpacing.width(8),
                        Icon(
                          LucideIcons.chevron_right,
                          size: 18,
                          color: theme.colorScheme.onPrimary,
                        )
                      ],
                    ),
                  ),
                  MySpacing.height(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MyText.bodyMedium(
                        "Already have an account? ",
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
                      ),
                      InkWell(
                        onTap: () => context.go('/login'),
                        child: MyText.bodyMedium(
                          "Sign In",
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

  Widget signupForm() {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          AuthNameField(
            controller: controller.nameController,
            outlineInputBorder: outlineInputBorder,
            theme: theme,
            validator: controller.validateName,
          ),
          MySpacing.height(20),
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
          MySpacing.height(20),
          AuthConfirmPasswordField(
            controller: controller.confirmPasswordController,
            outlineInputBorder: outlineInputBorder,
            theme: theme,
            validator: controller.validateConfirmPassword,
          ),
        ],
      ),
    );
  }

}
