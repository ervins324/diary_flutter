import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/database/hive_boxes.dart';
import '../../../core/theme/liquid_theme.dart';

/// Helper to resolve any file or image URL to a full network URI, local file path, or base64.
class AttachmentHelper {
  static String resolveUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';

    // Already a full HTTP/HTTPS URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Relative server path (e.g. /api/v1/files/UUID)
    if (trimmed.startsWith('/')) {
      final serverUrl = HiveBoxes.getServerUrl();
      final base = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;
      return '$base$trimmed';
    }

    // Local file path
    return trimmed;
  }

  static bool isLocalFile(String path) {
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('data:') ||
        path.startsWith('/api/')) {
      return false;
    }
    return File(path).existsSync();
  }

  static bool isBase64(String path) {
    return path.startsWith('data:image/');
  }

  static String formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static bool isImageAttachment(String type, String nameOrUrl) {
    if (type.toLowerCase() == 'image') return true;
    final lower = nameOrUrl.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }

  static Future<void> openFileOrUrl(String rawUrl, {String? localFilePath}) async {
    try {
      if (localFilePath != null && File(localFilePath).existsSync()) {
        final uri = Uri.file(localFilePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return;
        }
      }

      final resolved = resolveUrl(rawUrl);
      final uri = Uri.parse(resolved);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Ignored if unable to open
    }
  }
}

/// Full-screen interactive Lightbox image viewer with pinch-to-zoom, pan,
/// double-tap zoom, swipe navigation, zoom scale controls, and counter.
class LightboxGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const LightboxGallery({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  static void show(BuildContext context, {required List<String> images, int initialIndex = 0}) {
    if (images.isEmpty) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, anim, _) {
          return FadeTransition(
            opacity: anim,
            child: LightboxGallery(images: images, initialIndex: initialIndex),
          );
        },
      ),
    );
  }

  @override
  State<LightboxGallery> createState() => _LightboxGalleryState();
}

class _LightboxGalleryState extends State<LightboxGallery>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late final PageController _pageController;
  final TransformationController _transformController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  late AnimationController _animController;
  Animation<Matrix4>? _zoomAnimation;
  late final ValueNotifier<double> _scaleNotifier;
  late final ValueNotifier<bool> _isZoomedNotifier;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _scaleNotifier = ValueNotifier<double>(1.0);
    _isZoomedNotifier = ValueNotifier<bool>(false);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformController.value = _zoomAnimation!.value;
          _updateScale();
        }
      });

    _transformController.addListener(_updateScale);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _transformController.dispose();
    _scaleNotifier.dispose();
    _isZoomedNotifier.dispose();
    super.dispose();
  }

  void _updateScale() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if ((scale - _scaleNotifier.value).abs() > 0.01) {
      _scaleNotifier.value = scale;
      final zoomed = scale > 1.05;
      if (_isZoomedNotifier.value != zoomed) {
        _isZoomedNotifier.value = zoomed;
      }
    }
  }

  void _resetZoom() {
    _zoomTo(1.0);
  }

  void _zoomIn() {
    final target = (_scaleNotifier.value + 0.5).clamp(1.0, 4.0);
    _zoomTo(target);
  }

  void _zoomOut() {
    final target = (_scaleNotifier.value - 0.5).clamp(1.0, 4.0);
    _zoomTo(target);
  }

  void _zoomTo(double targetScale) {
    final currentMatrix = _transformController.value;
    final targetMatrix = Matrix4.identity()..scaleByDouble(targetScale, targetScale, 1.0, 1.0);

    _zoomAnimation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward(from: 0);
  }

  void _handleDoubleTap() {
    if (_scaleNotifier.value > 1.2) {
      _resetZoom();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final targetMatrix = Matrix4.identity()
        ..translateByDouble(-position.dx * 1.5, -position.dy * 1.5, 0.0, 1.0)
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);

      _zoomAnimation = Matrix4Tween(
        begin: _transformController.value,
        end: targetMatrix,
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

      _animController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = widget.images[_currentIndex];
    final total = widget.images.length;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      body: SafeArea(
        child: Stack(
          children: [
            // Center Image viewer with PageView decoupled from gesture rebuilds
            GestureDetector(
              onDoubleTapDown: (details) => _doubleTapDetails = details,
              onDoubleTap: _handleDoubleTap,
              child: ValueListenableBuilder<bool>(
                valueListenable: _isZoomedNotifier,
                builder: (context, isZoomed, _) {
                  return PageView.builder(
                    controller: _pageController,
                    physics: isZoomed
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    itemCount: total,
                    onPageChanged: (idx) {
                      setState(() {
                        _currentIndex = idx;
                      });
                      _transformController.value = Matrix4.identity();
                      _scaleNotifier.value = 1.0;
                      _isZoomedNotifier.value = false;
                    },
                    itemBuilder: (context, index) {
                      final rawUrl = widget.images[index];
                      return Center(
                        child: InteractiveViewer(
                          transformationController:
                              index == _currentIndex ? _transformController : null,
                          minScale: 0.8,
                          maxScale: 4.5,
                          clipBehavior: Clip.none,
                          child: _buildImageWidget(rawUrl),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Top Toolbar: Counter, Zoom controls, Download, Close
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  // Image Counter badge
                  if (total > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Zoom Controls pill - rebuilds only its own small label on zoom
                  ValueListenableBuilder<double>(
                    valueListenable: _scaleNotifier,
                    builder: (context, scale, _) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: scale > 1.0 ? _zoomOut : null,
                              icon: const Icon(Icons.remove_rounded, size: 18),
                              color: Colors.white,
                              disabledColor: Colors.white30,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                              tooltip: 'Zoom out',
                            ),
                            GestureDetector(
                              onTap: _resetZoom,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  '${(scale * 100).round()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: scale < 4.0 ? _zoomIn : null,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              color: Colors.white,
                              disabledColor: Colors.white30,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              padding: EdgeInsets.zero,
                              tooltip: 'Zoom in',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),

                  // Open / Download in external viewer button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: IconButton(
                      onPressed: () {
                        AttachmentHelper.openFileOrUrl(currentUrl);
                      },
                      icon: const Icon(Icons.open_in_browser_rounded, size: 18, color: Colors.white),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      tooltip: 'Open in external viewer',
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Close button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                      tooltip: 'Close',
                    ),
                  ),
                ],
              ),
            ),

            // Bottom dot indicator for multi-image gallery
            if (total > 1 && total <= 10)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (i) {
                    final isSel = i == _currentIndex;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isSel ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSel ? LiquidTheme.accentLight : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String rawUrl) {
    if (AttachmentHelper.isLocalFile(rawUrl)) {
      return Image.file(
        File(rawUrl),
        key: ValueKey(rawUrl),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _buildErrorWidget(),
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
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _buildErrorWidget(),
        );
      } catch (_) {
        return _buildErrorWidget();
      }
    }

    final fullUrl = AttachmentHelper.resolveUrl(rawUrl);
    return Image.network(
      fullUrl,
      key: ValueKey(fullUrl),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const Center(
          child: CircularProgressIndicator(color: LiquidTheme.accentLight),
        );
      },
      errorBuilder: (_, _, _) => _buildErrorWidget(),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.broken_image_rounded, size: 54, color: Colors.white38),
        SizedBox(height: 8),
        Text(
          'Failed to load image',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    );
  }
}
