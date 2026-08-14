import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:krishimandi/widgets/common/introduction_screen.dart';

class SignupIntroductionScreen extends StatelessWidget {
  const SignupIntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      items: const [
        IntroductionItem(
          icon: LucideIcons.badge_indian_rupee,
          color: Colors.orange,
          title: 'Billing charges pre-set',
          description:
              'Two default billing charges are added for you — one for buyers '
              'and one for sellers — so your bills are correct from day one.',
        ),
        IntroductionItem(
          icon: LucideIcons.rocket,
          color: Colors.deepPurple,
          title: 'Go live with your mandi',
          description:
              'Complete the final signup and your mandi is ready to go live — '
              'manage customers, billing, and stock all in one place.',
        ),
      ],
      onDone: () => context.go('/signup'),
    );
  }
}
