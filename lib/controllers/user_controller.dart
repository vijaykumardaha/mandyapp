import 'package:flutter/material.dart';
import 'package:krishimandi/utils/my_string_utils.dart';

class UserController {
  GlobalKey<FormState> formKey = GlobalKey();
  TextEditingController name = TextEditingController();
  TextEditingController mobile = TextEditingController();
  TextEditingController password = TextEditingController();

  String? validateName(String? text) {
    if (text == null || text.isEmpty) {
      return 'Please enter your business name';
    }
    return null;
  }

  String? validateMobileNumber(String? text) {
    if (text == null || text.isEmpty) {
      return 'Please enter a mobile number';
    }

    final RegExp regExp = RegExp(r'^\+?[1-9]\d{9,14}$');
    if (!regExp.hasMatch(text)) {
      return 'Please enter a valid mobile number';
    }
    return null;
  }

  String? validatePassword(String? text) {
    if (text == null || text.isEmpty) {
      return 'Please enter password';
    } else if (!MyStringUtils.validateStringRange(text, 6, 100)) {
      return 'Password must be between 6 and 100 characters';
    }
    return null;
  }
}
