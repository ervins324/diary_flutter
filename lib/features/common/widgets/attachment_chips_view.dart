import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/theme/liquid_theme.dart';
import '../../../models/homework_model.dart';
import 'lightbox_gallery.dart';

/// Unified component that displays:
/// 1. Tappable image thumbnails with tap-to-zoom opening [LightboxGallery].
/// 2. Document attachment chips (PDF, PPTX, links) with icon, name, size, and tap-to-open.
class AttachmentChipsView extends StatelessWidget {
  final List<String> images;
  final List<AttachmentItem> attachments;
  final bool isDark;
  final void Function(int index)? onRemoveImage;
  final void Function(int index)? onRemoveAttachment;

  const AttachmentChipsView({
    super.key,
    this.images = const [],
    this.attachments = const [],
    required this.isDark,
    this.onRemoveImage,
    this.onRemoveAttachment,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Collect all images (both direct string URLs and image attachments)
    final allImageUrls = <String>[];
    final imageAttachmentIndices = <int>[];

    for (final img in images) {
      if (img.trim().isNotEmpty) {
        allImageUrls.add(img);
      }
    }

    final nonImageAttachments = <MapEntry<int, AttachmentItem>>[];
    for (int i = 0; i < attachments.length; i++) {
      final att = attachments[i];
      if (AttachmentHelper.isImageAttachment(att.type, att.name) ||
          AttachmentHelper.isImageAttachment(att.type, att.url)) {
        allImageUrls.add(att.localFilePath ?? att.url);
        imageAttachmentIndices.add(i);
      } else {
        nonImageAttachments.add(MapEntry(i, att));
      }
    }

    if (allImageUrls.isEmpty && nonImageAttachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 1. Image Thumbnails Row / Wrap ──────────────────────────
        if (allImageUrls.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: allImageUrls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final url = allImageUrls[idx];
                return Stack(
                  key: ValueKey(url),
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: () {
                        LightboxGallery.show(
                          context,
                          images: allImageUrls,
                          initialIndex: idx,
                        );
                      },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                            width: 1.2,
                          ),
                          color: isDark ? const Color(0x331E293B) : const Color(0x33E2E8F0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildThumbnail(url),
                            // Subtle zoom icon overlay on bottom right
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.zoom_in_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Remove button when editing
                    if (onRemoveImage != null && idx < images.length)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => onRemoveImage!(idx),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: LiquidTheme.danger,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],

        // ── 2. Document & Link Attachment Chips ─────────────────────
        if (nonImageAttachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: nonImageAttachments.map((entry) {
              final originalIndex = entry.key;
              final att = entry.value;
              final isPdf = att.type == 'pdf' || att.name.toLowerCase().endsWith('.pdf');
              final isPresentation = att.type == 'presentation' ||
                  att.name.toLowerCase().endsWith('.pptx') ||
                  att.name.toLowerCase().endsWith('.ppt');
              final isLink = att.type == 'link' || att.url.startsWith('http');

              Color typeColor = LiquidTheme.accentLight;
              IconData typeIcon = Icons.description_rounded;

              if (isPdf) {
                typeColor = Colors.redAccent;
                typeIcon = Icons.picture_as_pdf_rounded;
              } else if (isPresentation) {
                typeColor = Colors.amberAccent;
                typeIcon = Icons.slideshow_rounded;
              } else if (isLink) {
                typeColor = Colors.lightBlueAccent;
                typeIcon = Icons.link_rounded;
              }

              final sizeStr = AttachmentHelper.formatBytes(att.size);

              return GestureDetector(
                onTap: () {
                  AttachmentHelper.openFileOrUrl(
                    att.url,
                    localFilePath: att.localFilePath,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x331E293B) : const Color(0x44CBD5E1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? LiquidTheme.darkBorder : LiquidTheme.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, size: 15, color: typeColor),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          att.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (sizeStr.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          sizeStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 12,
                        color: isDark ? LiquidTheme.darkTextMuted : LiquidTheme.lightTextMuted,
                      ),
                      if (onRemoveAttachment != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => onRemoveAttachment!(originalIndex),
                          child: const Icon(Icons.close_rounded, size: 14, color: LiquidTheme.danger),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildThumbnail(String rawUrl) {
    if (AttachmentHelper.isLocalFile(rawUrl)) {
      return Image.file(
        File(rawUrl),
        key: ValueKey(rawUrl),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        cacheWidth: 200,
        errorBuilder: (_, _, _) => _errorThumb(),
      );
    }

    if (AttachmentHelper.isBase64(rawUrl)) {
      try {
        final comma = rawUrl.indexOf(',');
        final data = comma >= 0 ? rawUrl.substring(comma + 1) : rawUrl;
        final bytes = base64Decode(data);
        return Image.memory(
          bytes,
          key: ValueKey(rawUrl),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          cacheWidth: 200,
          errorBuilder: (_, _, _) => _errorThumb(),
        );
      } catch (_) {
        return _errorThumb();
      }
    }

    final fullUrl = AttachmentHelper.resolveUrl(rawUrl);
    return Image.network(
      fullUrl,
      key: ValueKey(fullUrl),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: 200,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: LiquidTheme.accentLight),
          ),
        );
      },
      errorBuilder: (_, _, _) => _errorThumb(),
    );
  }

  Widget _errorThumb() {
    return const Center(
      child: Icon(Icons.broken_image_rounded, size: 24, color: Colors.white38),
    );
  }
}
