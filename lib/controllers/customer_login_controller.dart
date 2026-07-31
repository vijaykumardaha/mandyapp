import 'package:flutter/material.dart';

class CustomerLoginController {
  GlobalKey<FormState> formKey = GlobalKey();
  TextEditingController mandiIdController = TextEditingController();
  TextEditingController mobileController = TextEditingController();

  String? validateMandiId(String? text) {
    if (text == null || text.isEmpty) {
      return 'Please enter mandi id';
    }

    final RegExp regExp = RegExp(r'^\d+$');
    if (!regExp.hasMatch(text)) {
      return 'Please enter valid mandi id';
    }
    return null;
  }

  String? validateMobileNumber(String? text) {
    if (text == null || text.isEmpty) {
      return 'Please enter mobile number';
    }

    final RegExp regExp = RegExp(r'^\+?[1-9]\d{9,14}$');
    if (!regExp.hasMatch(text)) {
      return 'Please enter valid mobile number';
    }
    return null;
  }

  void dispose() {
    mandiIdController.dispose();
    mobileController.dispose();
  }

  void toggle() {}
}
