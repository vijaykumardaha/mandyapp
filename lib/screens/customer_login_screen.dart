import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandiapp/blocs/login/login_bloc.dart';
import 'package:mandiapp/controllers/customer_login_controller.dart';
import 'package:mandiapp/helpers/theme/app_theme.dart';
import 'package:mandiapp/models/mandi_model.dart';
import 'package:mandiapp/services/auth_api.dart';
import 'package:mandiapp/utils/info_controller.dart';
import 'package:mandiapp/widgets/auth/mandi_dropdown_field.dart';
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
  List<Mandi> _mandis = [];
  bool _loadingMandis = true;
  String? _mandiError;

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
    _loadMandis();
  }

  Future<void> _loadMandis() async {
    setState(() {
      _loadingMandis = true;
      _mandiError = null;
    });
    try {
      final mandis = await AuthApi().mandiList();
      if (mounted) {
        setState(() {
          _mandis = mandis;
          _loadingMandis = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mandiError = e.toString().replaceFirst('Exception: ', '');
          _loadingMandis = false;
        });
      }
    }
  }

  Widget _buildMandiLoading() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          MySpacing.width(12),
          const MyText.bodyMedium('Loading mandis...'),
        ],
      ),
    );
  }

  Widget _buildMandiError() {
    return Container(
      padding: MySpacing.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 20,
            color: theme.colorScheme.error,
          ),
          MySpacing.width(8),
          Expanded(
            child: MyText.bodySmall(
              _mandiError!,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          TextButton(
            onPressed: _loadMandis,
            child: const Text('Retry'),
          ),
        ],
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
                        if (_loadingMandis)
                          _buildMandiLoading()
                        else if (_mandiError != null)
                          _buildMandiError()
                        else
                          AuthMandiDropdownField(
                            mandis: _mandis,
                            value: controller.selectedMandi,
                            onChanged: (mandi) =>
                                controller.selectedMandi = mandi,
                            outlineInputBorder: outlineInputBorder,
                            theme: theme,
                            validator: controller.validateMandi,
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
                    onPressed: _loadingMandis
                        ? null
                        : () {
                            if (controller.formKey.currentState!.validate() &&
                                controller.selectedMandi != null) {
                              context.read<LoginBloc>().add(
                                    CustomerLoginSubmit(
                                      mandiId:
                                          controller.selectedMandi!.mandiId,
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
