import 'package:flutter/material.dart';

import '../models/track.dart';
import 'cover_image.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onLongPress,
    this.trailing,
    this.selected = false,
  });

  final Track track;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      selected: selected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: CoverImage(
            path: track.coverPath,
            placeholder: ColoredBox(
              color: cs.secondaryContainer,
              child: Icon(
                Icons.music_note_rounded,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${track.displayArtist} · ${track.displayAlbum}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ??
          (track.isFavorite
              ? Icon(Icons.favorite_rounded, color: cs.error, size: 20)
              : null),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
