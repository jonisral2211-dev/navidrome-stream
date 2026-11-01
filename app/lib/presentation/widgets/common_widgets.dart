import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/music_entities.dart';
import '../providers/providers.dart';
import '../screens/collection_screen.dart';
import 'cover_image.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
}

class LoadingBox extends StatelessWidget {
  const LoadingBox({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.spotifyGreen),
        ),
      );
}

class ErrorMessage extends StatelessWidget {
  const ErrorMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.subtitle),
          ),
        ),
      );
}

/// Fila de álbum o playlist que abre [CollectionScreen].
class CollectionTile extends ConsumerWidget {
  const CollectionTile({
    super.key,
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    this.coverArtId,
  });

  final String kind;
  final String id;
  final String title;
  final String subtitle;
  final String? coverArtId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CoverImage(url: coverUrl(ref, coverArtId), size: 48),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.subtitle),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CollectionScreen(
            kind: kind,
            id: id,
            title: title,
            coverArtId: coverArtId,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de álbum para la rejilla de Inicio.
class AlbumCard extends ConsumerWidget {
  const AlbumCard({super.key, required this.album});

  final Album album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CollectionScreen(
            kind: 'album',
            id: album.id,
            title: album.name,
            coverArtId: album.coverArtId,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: CoverImage(url: coverUrl(ref, album.coverArtId), radius: 8),
          ),
          const SizedBox(height: 8),
          Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            album.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.subtitle, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
