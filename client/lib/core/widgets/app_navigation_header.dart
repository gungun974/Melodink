import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class AppNavigationHeader extends StatelessWidget {
  const AppNavigationHeader({
    super.key,
    required this.child,
    this.title,
  });

  final Widget child;

  final Widget? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (GoRouter.of(context).canPop())
          AppBar(
            leading: IconButton(
              icon: SvgPicture.asset(
                "assets/icons/arrow-left.svg",
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            backgroundColor: const Color.fromRGBO(0, 0, 0, 0.08),
            shadowColor: Colors.transparent,
            title: title,
          ),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
