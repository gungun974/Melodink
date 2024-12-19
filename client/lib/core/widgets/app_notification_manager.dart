import 'package:adwaita_icons/adwaita_icons.dart';
import 'package:flutter/material.dart';
import 'package:melodink_client/core/widgets/max_container.dart';

enum AppNotificationType {
  info,
  success,
  warning,
  danger,
}

class AppNotificationManager extends StatefulWidget {
  final Widget child;

  const AppNotificationManager({
    super.key,
    required this.child,
  });

  static AppNotificationManagerState of(BuildContext context) {
    // Handles the case where the input context is a AppNotificationManager element.
    AppNotificationManagerState? appNotificationManager;
    if (context is StatefulElement &&
        context.state is AppNotificationManagerState) {
      appNotificationManager = context.state as AppNotificationManagerState;
    }

    appNotificationManager = appNotificationManager ??
        context.findAncestorStateOfType<AppNotificationManagerState>();

    assert(() {
      if (appNotificationManager == null) {
        throw FlutterError(
          "Can't find AppNotificationManager",
        );
      }
      return true;
    }());
    return appNotificationManager!;
  }

  @override
  State<AppNotificationManager> createState() => AppNotificationManagerState();
}

class _AppNotification {
  Key? key;
  String? title;
  String message;
  AppNotificationType type;
  bool show;

  _AppNotification({
    required this.key,
    required this.title,
    required this.message,
    required this.type,
    required this.show,
  });
}

class AppNotificationManagerState extends State<AppNotificationManager> {
  final List<_AppNotification> _notifications = [];

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        widget.child,
        ..._notifications.map((notificaiton) {
          return SafeArea(
            child: AnimatedSlide(
              key: notificaiton.key,
              offset: notificaiton.show
                  ? const Offset(0, 0)
                  : Offset(
                      0, MediaQuery.paddingOf(context).top == 0 ? -1 : -1.5),
              curve: const Cubic(0, .9, 0, 1),
              duration: const Duration(milliseconds: 670),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: _AppNotificationWidget(
                    title: notificaiton.title,
                    type: notificaiton.type,
                    message: notificaiton.message,
                  ),
                ),
              ),
            ),
          );
        })
      ],
    );
  }

  void notify(
    BuildContext context, {
    String? title,
    required String message,
    AppNotificationType type = AppNotificationType.info,
  }) async {
    final notification = _AppNotification(
      key: UniqueKey(),
      title: title,
      message: message,
      type: type,
      show: false,
    );

    setState(() {
      _notifications.add(
        notification,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        notification.show = true;
      });

      await Future.delayed(const Duration(milliseconds: 671, seconds: 2));

      setState(() {
        notification.show = false;
      });

      await Future.delayed(const Duration(milliseconds: 671));

      setState(() {
        _notifications.remove(notification);
      });
    });
  }
}

class _AppNotificationWidget extends StatelessWidget {
  const _AppNotificationWidget({
    required this.title,
    required this.type,
    required this.message,
  });

  final String? title;
  final AppNotificationType type;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaxContainer(
      maxWidth: 420,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(32, 38, 40, 1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: title != null
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: IntrinsicHeight(
            child: IntrinsicWidth(
              child: Row(
                children: [
                  switch (type) {
                    AppNotificationType.info => const AdwaitaIcon(
                        AdwaitaIcons.info,
                        color: Colors.white,
                        size: 24,
                      ),
                    AppNotificationType.success => Builder(builder: (context) {
                        return const Icon(
                          Icons.check,
                          color: Colors.lightGreenAccent,
                          size: 24,
                        );
                      }),
                    AppNotificationType.warning => const AdwaitaIcon(
                        AdwaitaIcons.warning,
                        color: Colors.white,
                        size: 24,
                      ),
                    AppNotificationType.danger => const AdwaitaIcon(
                        AdwaitaIcons.dialog_warning,
                        color: Colors.redAccent,
                        size: 24,
                      ),
                  },
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: switch (type) {
                                AppNotificationType.success =>
                                  Colors.lightGreenAccent,
                                AppNotificationType.danger =>
                                  const Color(0xFFE84E4A),
                                _ => Colors.white,
                              },
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: switch (type) {
                              AppNotificationType.success => Colors.lightGreen,
                              AppNotificationType.danger => Colors.red[300],
                              _ => Colors.white,
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
