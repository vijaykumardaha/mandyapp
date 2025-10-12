import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mandyapp/blocs/login/login_bloc.dart';
import 'package:mandyapp/controllers/signup_controller.dart';
import 'package:mandyapp/helpers/theme/app_theme.dart';
import 'package:mandyapp/helpers/widgets/my_button.dart';
import 'package:mandyapp/helpers/widgets/my_spacing.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';
import 'package:mandyapp/helpers/widgets/my_text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

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
            SnackBar snackBar = SnackBar(
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
                  MySpacing.height(40),
                  title(),
                  MySpacing.height(8),
                  subtitle(),
                  MySpacing.height(32),
                  signupForm(),
                  MySpacing.height(24),
                  signupBtn(),
                  MySpacing.height(16),
                  loginLink(),
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
        "Create Account",
        fontWeight: 700,
      ),
    );
  }

  Widget subtitle() {
    return Align(
      alignment: Alignment.centerLeft,
      child: MyText.bodyMedium(
        "Sign up to get started",
        color: theme.colorScheme.onBackground.withOpacity(0.6),
      ),
    );
  }

  Widget signupForm() {
    return Form(
      key: controller.formKey,
      child: Column(
        children: [
          nameField(),
          MySpacing.height(20),
          mobileField(),
          MySpacing.height(20),
          passwordField(),
          MySpacing.height(20),
          confirmPasswordField(),
        ],
      ),
    );
  }

  Widget nameField() {
    return TextFormField(
      style: MyTextStyle.bodyMedium(),
      decoration: InputDecoration(
        hintText: "Full Name",
        hintStyle: MyTextStyle.bodyMedium(),
        border: outlineInputBorder,
        enabledBorder: outlineInputBorder,
        focusedBorder: outlineInputBorder,
        prefixIcon: Icon(
          LucideIcons.user,
          size: 22,
          color: theme.colorScheme.primary,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.all(0),
      ),
      controller: controller.nameController,
      validator: controller.validateName,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      cursorColor: theme.colorScheme.primary,
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
        counterText: '',
      ),
      controller: controller.mobileController,
      validator: controller.validateMobileNumber,
      keyboardType: TextInputType.number,
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
          ),
        ),
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
      cursorColor: theme.colorScheme.primary,
    );
  }

  Widget confirmPasswordField() {
    return TextFormField(
      style: MyTextStyle.bodyMedium(),
      obscureText: controller.enableConfirm ? false : true,
      decoration: InputDecoration(
        hintText: "Confirm Password",
        hintStyle: MyTextStyle.bodyMedium(),
        border: outlineInputBorder,
        enabledBorder: outlineInputBorder,
        focusedBorder: outlineInputBorder,
        suffixIcon: InkWell(
          onTap: () {
            controller.toggleConfirm();
            setState(() {});
          },
          child: Icon(
            controller.enableConfirm
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        prefixIcon: Icon(
          LucideIcons.lock,
          size: 22,
          color: theme.colorScheme.primary,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.all(0),
      ),
      controller: controller.confirmPasswordController,
      validator: controller.validateConfirmPassword,
      keyboardType: TextInputType.text,
      cursorColor: theme.colorScheme.primary,
    );
  }

  Widget signupBtn() {
    return MyButton.block(
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
    );
  }

  Widget loginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MyText.bodyMedium(
          "Already have an account? ",
          color: theme.colorScheme.onBackground.withOpacity(0.6),
        ),
        InkWell(
          onTap: () {
            context.go('/login');
          },
          child: MyText.bodyMedium(
            "Sign In",
            fontWeight: 600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
