import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:mandiapp/widgets/common/my_text_style.dart';

class AuthPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final OutlineInputBorder outlineInputBorder;
  final ThemeData theme;
  final String? hintText;
  final String? Function(String?)? validator;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.outlineInputBorder,
    required this.theme,
    this.hintText,
    this.validator,
  });

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: MyTextStyle.bodyMedium(),
      obscureText: _obscureText,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Password',
        hintStyle: MyTextStyle.bodyMedium(),
        border: widget.outlineInputBorder,
        enabledBorder: widget.outlineInputBorder,
        focusedBorder: widget.outlineInputBorder,
        suffixIcon: InkWell(
          onTap: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
          child: Icon(
            _obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: widget.theme.colorScheme.primary,
          ),
        ),
        prefixIcon: Icon(
          LucideIcons.lock,
          size: 22,
          color: widget.theme.colorScheme.primary,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.all(0),
      ),
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: widget.theme.colorScheme.primary,
    );
  }
}
