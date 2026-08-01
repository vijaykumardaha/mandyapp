import 'package:flutter/material.dart';
import 'package:krishimandi/models/mandi_model.dart';

class CustomerLoginController {
  GlobalKey<FormState> formKey = GlobalKey();
  Mandi? selectedMandi;
  TextEditingController mobileController = TextEditingController();

  String? validateMandi(Mandi? mandi) {
    if (mandi == null) {
      return 'Please select mandi';
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
    mobileController.dispose();
  }

  void toggle() {}
}
