import 'track.dart';

class Album {
  const Album({
    required this.name,
    required this.artist,
    required this.tracks,
    this.coverPath,
    this.year = 0,
  });

  final String name;
  final String artist;
  final List<Track> tracks;
  final String? coverPath;
  final int year;

  int get trackCount => tracks.length;

  String get key => '${artist.trim().toLowerCase()}::${name.trim().toLowerCase()}';
}
