class ArtistModel {
  final int id;
  final int userId;

  final String name;

  const ArtistModel({
    required this.id,
    required this.userId,
    required this.name,
  });

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
    );
  }
}
