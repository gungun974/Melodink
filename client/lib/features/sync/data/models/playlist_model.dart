class PlaylistModel {
  final int id;
  final int userId;

  final String name;

  final String description;

  final String coverSignature;

  final List<int> tracks;

  const PlaylistModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.coverSignature,
    required this.tracks,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      coverSignature: json['cover_signature'],
      tracks: List<int>.from(json['tracks']),
    );
  }
}
