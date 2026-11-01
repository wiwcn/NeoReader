import 'package:equatable/equatable.dart';

class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    this.updatedAt,
    this.trackIds = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> trackIds;

  int get count => trackIds.length;

  Playlist copyWith({
    String? name,
    DateTime? updatedAt,
    List<String>? trackIds,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trackIds: trackIds ?? this.trackIds,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': (updatedAt ?? createdAt).toIso8601String(),
      };

  factory Playlist.fromMap(Map<String, Object?> m, {List<String> trackIds = const []}) =>
      Playlist(
        id: m['id']! as String,
        name: m['name']! as String,
        createdAt: DateTime.tryParse((m['created_at'] as String?) ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse((m['updated_at'] as String?) ?? ''),
        trackIds: trackIds,
      );

  @override
  List<Object?> get props => [id, name, trackIds];
}
