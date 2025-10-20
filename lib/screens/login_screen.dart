import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';
import 'package:mandyapp/controllers/login_controller.dart';

import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_button.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/helpers/widgets/my_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

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
            final snackBar = SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
              content: Text(state.error),
              backgroundColor: Colors.red,
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }

          if (state is LoginSuccess) {
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
                  title(),
                  MySpacing.height(8),
                  subtitle(),
                  MySpacing.height(32),
                  loginForm(),
                  MySpacing.height(24),
                  loginBtn(),
                  MySpacing.height(16),
                  signupLink(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget title() {
    return Align(
      alignment: Alignment.centerLeft,
      child: MyText.headlineMedium(
        "Sign In",
        fontWeight: 700,
      ),
    );
  }

  Widget subtitle() {
    return Align(
      alignment: Alignment.centerLeft,
      child: MyText.bodyMedium(
        "Welcome back! Please login to continue",
        color: theme.colorScheme.onBackground.withOpacity(0.6),
      ),
    );
  }

  Widget loginForm() {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [mobileField(), MySpacing.height(20), passwordField()],
      ),
    );
  }

  Widget mobileField() {
    return TextFormField(
      style: MyTextStyle.bodyMedium(),
      decoration: InputDecoration(
        hintText: "Mobile Number",
        hintStyle: MyTextStyle.bodyMedium(),
        border: outlineInputBorder,
        enabledBorder: outlineInputBorder,
        focusedBorder: outlineInputBorder,
        prefixIcon: Icon(
          LucideIcons.phone,
          size: 22,
          color: theme.colorScheme.primary,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.all(0),
        counterText: ''
      ),
      controller: controller.mobileController,
      validator: controller.validateMobileNumber,
      keyboardType: TextInputType.number,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: theme.colorScheme.primary,
      maxLength: 10,
    );
  }

  Widget passwordField() {
    return TextFormField(
      style: MyTextStyle.bodyMedium(),
      obscureText: controller.enable ? false : true,
      decoration: InputDecoration(
        hintText: "Password",
        hintStyle: MyTextStyle.bodyMedium(),
        border: outlineInputBorder,
        enabledBorder: outlineInputBorder,
        focusedBorder: outlineInputBorder,
        suffixIcon: InkWell(
            onTap: () {
              controller.toggle();
              setState(() {});
            },
            child: Icon(
              controller.enable
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: theme.colorScheme.primary,
            )),
        prefixIcon: Icon(
          LucideIcons.lock,
          size: 22,
          color: theme.colorScheme.primary,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.all(0),
      ),
      controller: controller.passwordController,
      validator: controller.validatePassword,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: theme.colorScheme.primary,
    );
  }

  Widget loginBtn() {
    return MyButton.block(
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
          MySpacing.width(8),
          Icon(
            LucideIcons.chevron_right,
            size: 18,
            color: theme.colorScheme.onPrimary,
          )
        ],
      ),
    );
  }

  Widget signupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MyText.bodyMedium(
          "Don't have an account? ",
          color: theme.colorScheme.onBackground.withOpacity(0.6),
        ),
        InkWell(
          onTap: () {
            context.go('/signup');
          },
          child: MyText.bodyMedium(
            "Sign Up",
            fontWeight: 600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
