import 'track.dart';

class Artist {
  const Artist({
    required this.name,
    required this.tracks,
  });

  final String name;
  final List<Track> tracks;

  int get trackCount => tracks.length;

  Set<String> get albums =>
      tracks.map((t) => t.displayAlbum).where((a) => a.isNotEmpty).toSet();
}
