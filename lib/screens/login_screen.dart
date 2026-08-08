import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:krishimandi/blocs/login/login_bloc.dart';
import 'package:krishimandi/controllers/customer_login_controller.dart';
import 'package:krishimandi/controllers/login_controller.dart';
import 'package:krishimandi/helpers/theme/app_theme.dart';
import 'package:krishimandi/models/mandi_model.dart';
import 'package:krishimandi/services/auth_api.dart';
import 'package:krishimandi/utils/info_controller.dart';
import 'package:krishimandi/widgets/auth/mandi_dropdown_field.dart';
import 'package:krishimandi/widgets/auth/mobile_field.dart';
import 'package:krishimandi/widgets/auth/password_field.dart';
import 'package:krishimandi/widgets/common/my_button.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

enum _LoginMode { staff, customer }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late ThemeData theme;
  late LoginController loginController;
  late CustomerLoginController customerController;
  late OutlineInputBorder outlineInputBorder;

  _LoginMode _mode = _LoginMode.staff;

  List<Mandi> _mandis = [];
  bool _loadingMandis = false;
  String? _mandiError;

  bool get _isCustomerMode => _mode == _LoginMode.customer;

  @override
  void initState() {
    super.initState();
    theme = AppTheme.shoppingManagerTheme;
    loginController = LoginController();
    customerController = CustomerLoginController();
    outlineInputBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: theme.dividerColor,
      ),
    );
    if (_isCustomerMode) {
      _loadMandis();
    }
  }

  @override
  void dispose() {
    customerController.dispose();
    super.dispose();
  }

  void _switchMode(_LoginMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    if (_isCustomerMode && _mandis.isEmpty) {
      _loadMandis();
    }
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

  void _submitStaff() {
    if (loginController.formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
            LoginSubmit(
              mobile: loginController.mobileController.text,
              password: loginController.passwordController.text,
            ),
          );
    }
  }

  void _submitCustomer() {
    if (customerController.formKey.currentState!.validate() &&
        customerController.selectedMandi != null) {
      context.read<LoginBloc>().add(
            CustomerLoginSubmit(
              mandiId: customerController.selectedMandi!.mandiId,
              mobile: customerController.mobileController.text,
            ),
          );
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

  Widget _buildStaffFields() {
    return Column(
      children: [
        AuthMobileField(
          controller: loginController.mobileController,
          outlineInputBorder: outlineInputBorder,
          theme: theme,
          validator: loginController.validateMobileNumber,
        ),
        MySpacing.height(20),
        AuthPasswordField(
          controller: loginController.passwordController,
          outlineInputBorder: outlineInputBorder,
          theme: theme,
          validator: loginController.validatePassword,
        ),
      ],
    );
  }

  Widget _buildCustomerFields() {
    return Column(
      children: [
        if (_loadingMandis)
          _buildMandiLoading()
        else if (_mandiError != null)
          _buildMandiError()
        else
          AuthMandiDropdownField(
            mandis: _mandis,
            value: customerController.selectedMandi,
            onChanged: (mandi) => customerController.selectedMandi = mandi,
            outlineInputBorder: outlineInputBorder,
            theme: theme,
            validator: customerController.validateMandi,
          ),
        MySpacing.height(20),
        AuthMobileField(
          controller: customerController.mobileController,
          outlineInputBorder: outlineInputBorder,
          theme: theme,
          validator: customerController.validateMobileNumber,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginFailure) {
            Info.error(state.error, context: context);
          }

          if (state is LoginCustomerFailure) {
            Info.error(state.error, context: context);
          }

          if (state is LoginSuccess) {
            context.go('/home');
          }

          if (state is LoginCustomerSuccess) {
            context.go('/customer-home');
          }
        },
        builder: (context, state) {
          if (state is LoginLoading ||
              state is SyncLoading ||
              state is LoginCustomerLoading) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                ],
              ),
            );
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: MySpacing.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MySpacing.height(60),
                  const MyText.headlineMedium(
                    'Login',
                    fontWeight: 700,
                  ),
                  MySpacing.height(8),
                  MyText.bodyMedium(
                    _isCustomerMode
                        ? 'Login with your mandi and mobile number'
                        : 'Welcome back! Please login to continue',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  MySpacing.height(28),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<_LoginMode>(
                      segments: const [
                        ButtonSegment(
                          value: _LoginMode.staff,
                          label: Text('Mandi Login'),
                        ),
                        ButtonSegment(
                          value: _LoginMode.customer,
                          label: Text('Customer Login'),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selection) =>
                          _switchMode(selection.first),
                      showSelectedIcon: false,
                    ),
                  ),
                  MySpacing.height(28),
                  Form(
                    key: _isCustomerMode
                        ? customerController.formKey
                        : loginController.formKey,
                    child: _isCustomerMode
                        ? _buildCustomerFields()
                        : _buildStaffFields(),
                  ),
                  MySpacing.height(24),
                  MyButton.block(
                    padding: MySpacing.y(20),
                    onPressed:
                        _isCustomerMode && _loadingMandis ? null : _submit,
                    backgroundColor: theme.colorScheme.primary,
                    elevation: 0,
                    borderRadiusAll: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MyText.bodySmall(
                          'Login'.toUpperCase(),
                          fontWeight: 700,
                          color: theme.colorScheme.onPrimary,
                          letterSpacing: 0.5,
                        ),
                      ],
                    ),
                  ),
                  if (!_isCustomerMode) ...[
                    MySpacing.height(20),
                    Container(
                      padding: MySpacing.xy(16, 12),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: MyText.bodyMedium(
                              "Haven't registered your mandi yet? ",
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          InkWell(
                            onTap: () => context.go('/signup-intro'),
                            child: MyText.bodyMedium(
                              'Register Mandi',
                              fontWeight: 700,
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MySpacing.height(8),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  VoidCallback? get _submit => _isCustomerMode ? _submitCustomer : _submitStaff;
}
