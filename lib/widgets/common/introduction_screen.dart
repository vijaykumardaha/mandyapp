import 'package:flutter/material.dart';
import 'package:krishimandi/widgets/common/my_button.dart';
import 'package:krishimandi/widgets/common/my_spacing.dart';
import 'package:krishimandi/widgets/common/my_text.dart';

class IntroductionItem {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const IntroductionItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

class IntroductionScreen extends StatefulWidget {
  final List<IntroductionItem> items;
  final VoidCallback onDone;
  final String skipLabel;
  final String nextLabel;
  final String doneLabel;

  const IntroductionScreen({
    super.key,
    required this.items,
    required this.onDone,
    this.skipLabel = 'Skip',
    this.nextLabel = 'Next',
    this.doneLabel = 'Get Started',
  });

  @override
  State<IntroductionScreen> createState() => _IntroductionScreenState();
}

class _IntroductionScreenState extends State<IntroductionScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  bool get _isLastPage => _currentIndex == widget.items.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_isLastPage) {
      widget.onDone();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: MyButton.text(
                onPressed: widget.onDone,
                child: Padding(
                  padding: MySpacing.xy(20, 12),
                  child: MyText.bodyMedium(
                    widget.skipLabel,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.items.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) =>
                    _IntroductionPage(item: widget.items[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.items.length, (index) {
                final selected = index == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: MySpacing.x(4),
                  width: selected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            MySpacing.height(28),
            Padding(
              padding: MySpacing.xy(20, 0),
              child: MyButton.block(
                padding: MySpacing.y(18),
                onPressed: _goToNextPage,
                backgroundColor: theme.colorScheme.primary,
                elevation: 0,
                borderRadiusAll: 24,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MyText.bodySmall(
                      (_isLastPage ? widget.doneLabel : widget.nextLabel)
                          .toUpperCase(),
                      fontWeight: 700,
                      color: theme.colorScheme.onPrimary,
                      letterSpacing: 0.5,
                    ),
                    MySpacing.width(8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
            ),
            MySpacing.height(24),
          ],
        ),
      ),
    );
  }
}

class _IntroductionPage extends StatelessWidget {
  final IntroductionItem item;

  const _IntroductionPage({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: MySpacing.xy(32, 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.color.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.color.withValues(alpha: 0.2),
                ),
                child: Icon(item.icon, size: 48, color: item.color),
              ),
            ),
          ),
          MySpacing.height(40),
          MyText.headlineSmall(
            item.title,
            fontWeight: 700,
            textAlign: TextAlign.center,
          ),
          MySpacing.height(12),
          MyText.bodyMedium(
            item.description,
            textAlign: TextAlign.center,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
