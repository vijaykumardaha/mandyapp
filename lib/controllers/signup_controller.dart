import 'package:mandyapp/helpers/utils/my_string_utils.dart';
import 'package:flutter/material.dart';

class SignupController {
  GlobalKey<FormState> formKey = GlobalKey();
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  bool enable = false;
  bool enableConfirm = false;

  String? validateName(String? text) {
    if (text == null || text.isEmpty) {
      return "Please enter your name";
    }
    if (text.length < 2) {
      return "Name must be at least 2 characters";
    }
    return null;
  }

  String? validateMobileNumber(String? text) {
    if (text == null || text.isEmpty) {
      return "Please enter mobile number";
    }

    RegExp regExp = RegExp(r'^\+?[1-9]\d{9,14}$');
    if (!regExp.hasMatch(text)) {
      return 'Please enter valid mobile number';
    }
    return null;
  }

  String? validatePassword(String? text) {
    if (text == null || text.isEmpty) {
      return "Please enter password";
    } else if (!MyStringUtils.validateStringRange(text, 6, 100)) {
      return "Password must be between 6 to 100";
    }
    return null;
  }

  String? validateConfirmPassword(String? text) {
    if (text == null || text.isEmpty) {
      return "Please confirm your password";
    }
    if (text != passwordController.text) {
      return "Passwords do not match";
    }
    return null;
  }

  void toggle() {
    enable = !enable;
  }

  void toggleConfirm() {
    enableConfirm = !enableConfirm;
  }

  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
  }
}
