import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:krishimandi/blocs/login/login_bloc.dart';
import 'package:krishimandi/controllers/signup_controller.dart';
import 'package:krishimandi/helpers/theme/app_theme.dart';
import 'package:krishimandi/utils/info_controller.dart';
import 'package:krishimandi/widgets/auth/confirm_password_field.dart';
import 'package:krishimandi/widgets/auth/mobile_field.dart';
import 'package:krishimandi/widgets/auth/name_field.dart';
import 'package:krishimandi/widgets/auth/password_field.dart';
import 'package:krishimandi/widgets/common/my_button.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
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
        listener: (context, state) {
          if (state is LoginFailure) {
            Info.error(state.error, context: context);
          }

          if (state is LoginSuccess) {
            context.go('/home');
          }
        },
        builder: (context, state) {
          if (state is LoginLoading || state is SyncLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (state is SyncLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Syncing your data...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            );
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: MySpacing.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  MySpacing.height(40),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: MyText.headlineMedium(
                      'Create Account',
                      fontWeight: 700,
                    ),
                  ),
                  MySpacing.height(8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MyText.bodyMedium(
                      'Sign up to get started',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                          'Sign Up'.toUpperCase(),
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
                        'Already have an account? ',
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      InkWell(
                        onTap: () => context.go('/login'),
                        child: MyText.bodyMedium(
                          'Login',
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
