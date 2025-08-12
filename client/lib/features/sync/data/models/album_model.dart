class AlbumModel {
  final int id;
  final int userId;

  final String name;

  final List<int> artists;

  final String coverSignature;

  const AlbumModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.artists,
    required this.coverSignature,
  });

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      coverSignature: json['cover_signature'],
      artists: List<int>.from(json['artists']),
    );
  }
}
