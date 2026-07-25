import 'package:flutter/material.dart';
import 'package:mandyapp/helpers/widgets/my_text.dart';

class ContentSectionTitle extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const ContentSectionTitle({
    super.key,
    required this.title,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return MyText.titleMedium(
      title,
      fontWeight: 600,
      color: theme.colorScheme.primary,
    );
  }
}
