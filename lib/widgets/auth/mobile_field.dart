import 'package:flutter/material.dart';
import 'package:mandyapp/widgets/common/my_text_style.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class AuthMobileField extends StatelessWidget {
  final TextEditingController controller;
  final OutlineInputBorder outlineInputBorder;
  final ThemeData theme;
  final String? Function(String?)? validator;

  const AuthMobileField({
    super.key,
    required this.controller,
    required this.outlineInputBorder,
    required this.theme,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
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
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.number,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: theme.colorScheme.primary,
      maxLength: 10,
    );
  }
}
