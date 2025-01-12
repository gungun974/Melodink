import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final _streamController = StreamController.broadcast();

void useAutoCloseContextMenuOnScroll({
  required ScrollController scrollController,
}) {
  void onScroll() {
    _streamController.add(null);
  }

  useEffect(() {
    scrollController.addListener(onScroll);

    return () {
      scrollController.removeListener(onScroll);
    };
  }, []);
}

class AutoCloseContextMenuOnScroll extends HookWidget {
  final Widget child;

  final MenuController menuController;

  const AutoCloseContextMenuOnScroll({
    super.key,
    required this.child,
    required this.menuController,
  });

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      final subscription = _streamController.stream.listen((_) {
        menuController.close();
      });

      return subscription.cancel;
    }, []);

    return child;
  }
}
