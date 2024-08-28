import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:melodink_client/core/widgets/app_button.dart';
import 'package:melodink_client/features/auth/domain/providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Image(image: AssetImage("assets/melodink_fulllogo.png")),
            AppButton(
              text: "Debug Logout",
              type: AppButtonType.primary,
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).logout();
              },
            )
          ],
        ),
      ),
    );
  }
}
