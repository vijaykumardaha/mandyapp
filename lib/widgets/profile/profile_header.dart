import 'package:flutter/material.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class ProfileHeader extends StatelessWidget {
  final String? name;
  final String? mobile;
  final ThemeData theme;

  const ProfileHeader({
    super.key,
    this.name,
    this.mobile,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.person,
              size: 50,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          MySpacing.height(12),
          MyText.titleLarge(
            name ?? 'User',
            fontWeight: 600,
          ),
          MySpacing.height(4),
          MyText.bodyMedium(
            mobile ?? '',
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
