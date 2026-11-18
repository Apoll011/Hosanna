import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../folders/domain/folder_customization.dart';

/// Resolves a Studio collection cover (`data:` URL or http(s)) for Flutter.
ImageProvider? collectionImageProvider(String? image) {
  if (image == null || image.isEmpty) return null;

  if (image.startsWith('data:')) {
    final comma = image.indexOf(',');
    if (comma < 0 || comma >= image.length - 1) return null;
    try {
      return MemoryImage(base64Decode(image.substring(comma + 1)));
    } catch (_) {
      return null;
    }
  }

  if (image.startsWith('http://') || image.startsWith('https://')) {
    return CachedNetworkImageProvider(image);
  }

  return null;
}

/// Color + icon chip used when a collection has no cover image.
class CollectionAccentBadge extends StatelessWidget {
  const CollectionAccentBadge({
    super.key,
    required this.colorId,
    required this.iconId,
    this.size = 40,
  });

  final String colorId;
  final String iconId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = folderColorOf(colorId);
    final icon = folderIconOf(iconId, hasContents: true);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}
