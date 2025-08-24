import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

enum AppScreenTypeLayout { mobile, desktop }

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

class AppScreenTypeProvider extends StatefulWidget {
  final Widget child;

  const AppScreenTypeProvider({super.key, required this.child});

  @override
  State<AppScreenTypeProvider> createState() => _AppScreenTypeProviderState();
}

class _AppScreenTypeProviderState extends State<AppScreenTypeProvider>
    with WidgetsBindingObserver {
  AppScreenTypeLayout deviceType = AppScreenTypeLayout.mobile;

  final dispatcher = WidgetsBinding.instance.platformDispatcher;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    deviceType = getAppScreenType(
      dispatcher.views.first.physicalSize /
          dispatcher.views.first.devicePixelRatio,
    );
  }

  @override
  void didChangeMetrics() {
    final newDeviceType = getAppScreenType(
      dispatcher.views.first.physicalSize /
          dispatcher.views.first.devicePixelRatio,
    );
    if (newDeviceType != deviceType) {
      setState(() {
        deviceType = newDeviceType;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(value: deviceType, child: widget.child);
  }
}

class AppScreenTypeLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext, AppScreenTypeLayout) builder;

  const AppScreenTypeLayoutBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final deviceType = context.watch<AppScreenTypeLayout>();

    return builder(context, deviceType);
  }
}

class AppScreenTypeLayoutBuilders extends StatelessWidget {
  final Widget Function(BuildContext)? mobile;
  final Widget Function(BuildContext)? desktop;

  const AppScreenTypeLayoutBuilders({super.key, this.mobile, this.desktop});

  @override
  Widget build(BuildContext context) {
    final deviceType = context.watch<AppScreenTypeLayout>();

    switch (deviceType) {
      case AppScreenTypeLayout.mobile:
        final mobileBuilder = mobile;

        if (mobileBuilder != null) {
          return mobileBuilder(context);
        }

        return const SizedBox.shrink();
      case AppScreenTypeLayout.desktop:
        final desktopBuilder = desktop;

        if (desktopBuilder != null) {
          return desktopBuilder(context);
        }

        return const SizedBox.shrink();
    }
  }
}
