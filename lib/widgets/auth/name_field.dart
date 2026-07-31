import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:mandiapp/widgets/common/my_text_style.dart';

class AuthNameField extends StatelessWidget {
  final TextEditingController controller;
  final OutlineInputBorder outlineInputBorder;
  final ThemeData theme;
  final String? Function(String?)? validator;

  const AuthNameField({
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
        hintText: 'Mandi Name',
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
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      cursorColor: theme.colorScheme.primary,
    );
  }
}
