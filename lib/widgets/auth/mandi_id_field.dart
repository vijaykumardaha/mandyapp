import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:mandiapp/widgets/common/my_text_style.dart';

class AuthMandiIdField extends StatelessWidget {
  final TextEditingController controller;
  final OutlineInputBorder outlineInputBorder;
  final ThemeData theme;
  final String? Function(String?)? validator;

  const AuthMandiIdField({
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
        hintText: 'Mandi ID',
        hintStyle: MyTextStyle.bodyMedium(),
        border: outlineInputBorder,
        enabledBorder: outlineInputBorder,
        focusedBorder: outlineInputBorder,
        prefixIcon: Icon(
          LucideIcons.hash,
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
    );
  }
}
