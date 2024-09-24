import 'package:melodink_client/features/library/domain/entities/artist.dart';

class MinimalArtistModel {
  final String id;

  final String name;

  const MinimalArtistModel({
    required this.id,
    required this.name,
  });

  MinimalArtist toMinimalArtist() {
    return MinimalArtist(
      id: id,
      name: name,
    );
  }

  factory MinimalArtistModel.fromMinimalArtist(MinimalArtist artist) {
    return MinimalArtistModel(
      id: artist.id,
      name: artist.name,
    );
  }

  factory MinimalArtistModel.fromJson(Map<String, dynamic> json) {
    return MinimalArtistModel(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
