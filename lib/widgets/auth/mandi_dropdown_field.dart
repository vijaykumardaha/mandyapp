import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:mandiapp/models/mandi_model.dart';
import 'package:mandiapp/widgets/common/my_text_style.dart';

class AuthMandiDropdownField extends StatelessWidget {
  final List<Mandi> mandis;
  final Mandi? value;
  final ValueChanged<Mandi?>? onChanged;
  final String? Function(Mandi?)? validator;
  final OutlineInputBorder outlineInputBorder;
  final ThemeData theme;

  const AuthMandiDropdownField({
    super.key,
    required this.mandis,
    required this.value,
    required this.onChanged,
    required this.outlineInputBorder,
    required this.theme,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Mandi>(
      value: value,
      isExpanded: true,
      style: MyTextStyle.bodyMedium(),
      decoration: InputDecoration(
        hintText: 'Select Mandi',
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
      items: mandis
          .map((mandi) => DropdownMenuItem<Mandi>(
                value: mandi,
                child: Text(
                  mandi.mandiName,
                  style: MyTextStyle.bodyMedium(),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
