import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

ValueNotifier<T> useProvider<T>(WidgetRef ref, ProviderListenable<T> provider) {
  final state = useState(ref.read(provider));

  ref.listen(provider, (_, value) {
    state.value = value;
  });

  return state;
}

ValueNotifier<T> useProviderAsync<T>(
    WidgetRef ref, ProviderListenable<AsyncValue<T>> provider, T defaultValue) {
  final state = useState(ref.read(provider).valueOrNull ?? defaultValue);

  ref.listen(provider, (_, value) {
    state.value = value.valueOrNull ?? defaultValue;
  });

  return state;
}
