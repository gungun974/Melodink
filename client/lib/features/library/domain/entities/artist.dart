import 'package:equatable/equatable.dart';

class MinimalArtist extends Equatable {
  final String id;
  final String name;

  const MinimalArtist({
    required this.id,
    required this.name,
  });

  MinimalArtist copyWith({
    String? id,
    String? name,
  }) {
    return MinimalArtist(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
      ];
}
