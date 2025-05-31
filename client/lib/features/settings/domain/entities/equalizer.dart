import 'package:equatable/equatable.dart';

class AppEqualizer extends Equatable {
  final bool enabled;

  // Frequency / Gain
  final Map<double, double> bands;

  const AppEqualizer({
    required this.enabled,
    required this.bands,
  });

  @override
  List<Object?> get props => [
        enabled,
        bands,
      ];
}
