import 'package:mandyapp/helpers/utils/my_string_utils.dart';
import 'package:flutter/material.dart';

class LoginController {
  GlobalKey<FormState> formKey = GlobalKey();
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool enable = false;

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

  void toggle() {
    enable = !enable;
  }
}
