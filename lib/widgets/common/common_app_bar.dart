import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool centerTitle;

  const CommonAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.cardColor;
    final fgColor = foregroundColor ?? theme.colorScheme.onSurface;

    final bool canPop = GoRouter.of(context).canPop();

    return AppBar(
      backgroundColor: bgColor,
      elevation: elevation,
      centerTitle: centerTitle,
      toolbarHeight: kToolbarHeight + 20,
      leading: showBackButton && canPop
          ? Padding(
              padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: fgColor,
                  ),
                ),
              ),
            )
          : null,
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null),
      foregroundColor: fgColor,
      actions: actions,
    );
  }
}
