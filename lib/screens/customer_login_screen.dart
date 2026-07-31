import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandiapp/blocs/login/login_bloc.dart';
import 'package:mandiapp/controllers/customer_login_controller.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/utils/info_controller.dart';
import 'package:mandiapp/widgets/auth/mandi_id_field.dart';
import 'package:mandiapp/widgets/auth/mobile_field.dart';
import 'package:mandiapp/widgets/common/my_button.dart';
import 'package:mandiapp/widgets/common/my_spacing.dart';
import 'package:mandiapp/widgets/common/my_text.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  late ThemeData theme;
  late CustomerLoginController controller;
  late OutlineInputBorder outlineInputBorder;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    controller = CustomerLoginController();
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
          if (state is LoginCustomerFailure) {
            Info.error(state.error, context: context);
          }

          if (state is LoginCustomerSuccess) {
            context.go('/customer-home');
          }
        },
        builder: (context, state) {
          if (state is LoginCustomerLoading) {
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
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: MyText.headlineMedium(
                      'Customer Login',
                      fontWeight: 700,
                    ),
                  ),
                  MySpacing.height(8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MyText.bodyMedium(
                      'Login with your mandi id and mobile number',
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  MySpacing.height(32),
                  Form(
                    key: controller.formKey,
                    child: Column(
                      children: [
                        AuthMandiIdField(
                          controller: controller.mandiIdController,
                          outlineInputBorder: outlineInputBorder,
                          theme: theme,
                          validator: controller.validateMandiId,
                        ),
                        MySpacing.height(20),
                        AuthMobileField(
                          controller: controller.mobileController,
                          outlineInputBorder: outlineInputBorder,
                          theme: theme,
                          validator: controller.validateMobileNumber,
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
                              CustomerLoginSubmit(
                                mandiId: int.parse(
                                    controller.mandiIdController.text),
                                mobile: controller.mobileController.text,
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
                        MyText.bodySmall('Login'.toUpperCase(),
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
                        'Login as admin or staff? ',
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
}
