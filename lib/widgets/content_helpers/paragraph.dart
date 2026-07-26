import 'package:flutter/material.dart';
import 'package:mandyapp/widgets/common/my_text.dart';

class ContentParagraph extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const ContentParagraph({
    super.key,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return MyText.bodyMedium(
      text,
      color: theme.colorScheme.onBackground.withOpacity(0.8),
      height: 1.6,
    );
  }
}
