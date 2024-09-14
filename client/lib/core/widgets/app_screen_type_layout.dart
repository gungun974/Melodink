import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

enum AppScreenTypeLayout {
  mobile,
  desktop,
}

AppScreenTypeLayout getAppScreenType(Size size) {
  var deviceType = getDeviceType(size);

  switch (deviceType) {
    case DeviceScreenType.mobile:
      return AppScreenTypeLayout.mobile;
    case DeviceScreenType.watch:
      return AppScreenTypeLayout.mobile;
    default:
      return AppScreenTypeLayout.desktop;
  }
}

class AppScreenTypeLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext, AppScreenTypeLayout) builder;

  const AppScreenTypeLayoutBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (contex) => builder(context, AppScreenTypeLayout.mobile),
      desktop: (contex) => builder(context, AppScreenTypeLayout.desktop),
    );
  }
}

class AppScreenTypeLayoutBuilders extends StatelessWidget {
  final Widget Function(BuildContext)? mobile;
  final Widget Function(BuildContext)? desktop;

  const AppScreenTypeLayoutBuilders({
    super.key,
    this.mobile,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: (contex) {
        final mobileBuilder = mobile;

        if (mobileBuilder != null) {
          return mobileBuilder(context);
        }

        return const SizedBox.shrink();
      },
      desktop: (contex) {
        final desktopBuilder = desktop;

        if (desktopBuilder != null) {
          return desktopBuilder(context);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
