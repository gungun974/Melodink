import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// Creates [ListController] that will be disposed automatically.
///
/// See also:
/// - [ListController]
ListController useListController({
  List<Object?>? keys,
}) {
  return use(
    _ListControllerHook(
      keys: keys,
    ),
  );
}

class _ListControllerHook extends Hook<ListController> {
  const _ListControllerHook({
    super.keys,
  });

  @override
  HookState<ListController, Hook<ListController>> createState() =>
      _ListControllerHookState();
}

class _ListControllerHookState
    extends HookState<ListController, _ListControllerHook> {
  late final controller = ListController();

  @override
  ListController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'useListController';
}
