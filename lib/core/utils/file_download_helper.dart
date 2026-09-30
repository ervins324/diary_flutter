import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_localizations.dart';
import '../theme/liquid_theme.dart';
import '../../features/common/widgets/lightbox_gallery.dart';

/// Result object for file download or save operations.
class DownloadResult {
  final bool success;
  final String? filePath;
  final String? fileName;
  final String? errorMessage;

  const DownloadResult({
    required this.success,
    this.filePath,
    this.fileName,
    this.errorMessage,
  });
}

/// Robust file downloader and local storage saver supporting:
/// 1. Base64 encoded image data URLs (common in offline and synced homework attachments).
/// 2. Server file endpoints (/api/v1/files/{id} with download=true).
/// 3. External HTTP/HTTPS URLs.
/// 4. Staged local disk files.
class FileDownloadHelper {
  /// Test override hook for headless unit testing
  static Directory? overrideSaveDirectory;

  /// Resolves the optimal directory for saving files accessible to the user.
  static Future<Directory> getSaveDirectory() async {
    if (overrideSaveDirectory != null) {
      return overrideSaveDirectory!;
    }

    if (Platform.isAndroid) {
      // 1. Primary Android public Downloads directory
      try {
        final publicDownload = Directory('/storage/emulated/0/Download');
        if (await publicDownload.exists()) {
          return publicDownload;
        }
      } catch (_) {}

      // 2. path_provider downloads directory
      try {
        final dir = await getDownloadsDirectory();
        if (dir != null && await dir.exists()) {
          return dir;
        }
      } catch (_) {}

      // 3. App external files directory (always accessible on Android without special permissions)
      try {
        final ext = await getExternalStorageDirectory();
        if (ext != null && await ext.exists()) {
          return ext;
        }
      } catch (_) {}
    }

    // Default for iOS / macOS / Windows / Linux
    try {
      final dir = await getDownloadsDirectory();
      if (dir != null) return dir;
    } catch (_) {}

    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {}

    return Directory.systemTemp;
  }

  /// Sanitizes raw filename to prevent invalid filesystem characters.
  static String sanitizeFileName(String name) {
    var clean = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (clean.isEmpty) {
      clean = 'file_${DateTime.now().millisecondsSinceEpoch}';
    }
    return clean;
  }

  /// Extracts file extension from MIME or URL.
  static String guessExtension(String typeOrUrl, [String defaultExt = '.jpg']) {
    final lower = typeOrUrl.toLowerCase();
    if (lower.contains('png')) return '.png';
    if (lower.contains('webp')) return '.webp';
    if (lower.contains('gif')) return '.gif';
    if (lower.contains('pdf')) return '.pdf';
    if (lower.contains('pptx')) return '.pptx';
    if (lower.contains('ppt')) return '.ppt';
    if (lower.contains('docx')) return '.docx';
    if (lower.contains('doc')) return '.doc';
    if (lower.contains('jpeg') || lower.contains('jpg')) return '.jpg';
    return defaultExt;
  }

  /// Saves or downloads any file or image to the user's Downloads directory.
  static Future<DownloadResult> downloadOrSave({
    required String rawUrl,
    String? preferredFileName,
    String? localFilePath,
  }) async {
    try {
      final targetDir = await getSaveDirectory();
      final urlTrimmed = rawUrl.trim();

      // Case 1: Local file already on disk (e.g. staged attachment)
      if (localFilePath != null && File(localFilePath).existsSync()) {
        final sourceFile = File(localFilePath);
        final fileName = sanitizeFileName(
          preferredFileName ?? sourceFile.uri.pathSegments.last,
        );
        final destination = _resolveUniqueFile(targetDir, fileName);
        await sourceFile.copy(destination.path);
        return DownloadResult(
          success: true,
          filePath: destination.path,
          fileName: destination.uri.pathSegments.last,
        );
      }

      if (AttachmentHelper.isLocalFile(urlTrimmed)) {
        final sourceFile = File(urlTrimmed);
        final fileName = sanitizeFileName(
          preferredFileName ?? sourceFile.uri.pathSegments.last,
        );
        final destination = _resolveUniqueFile(targetDir, fileName);
        await sourceFile.copy(destination.path);
        return DownloadResult(
          success: true,
          filePath: destination.path,
          fileName: destination.uri.pathSegments.last,
        );
      }

      // Case 2: Base64 Data URL (e.g. data:image/jpeg;base64,...)
      if (AttachmentHelper.isBase64(urlTrimmed) ||
          urlTrimmed.startsWith('data:')) {
        final comma = urlTrimmed.indexOf(',');
        final header = comma >= 0 ? urlTrimmed.substring(0, comma) : '';
        final base64Data = comma >= 0
            ? urlTrimmed.substring(comma + 1)
            : urlTrimmed;
        final bytes = base64Decode(base64Data);

        String ext = guessExtension(header, '.jpg');
        String baseName =
            preferredFileName ??
            'image_${DateTime.now().millisecondsSinceEpoch}$ext';
        if (!baseName.contains('.')) {
          baseName += ext;
        }
        final destination = _resolveUniqueFile(
          targetDir,
          sanitizeFileName(baseName),
        );
        await destination.writeAsBytes(bytes);
        return DownloadResult(
          success: true,
          filePath: destination.path,
          fileName: destination.uri.pathSegments.last,
        );
      }

      // Case 3: Network or API endpoint URL
      String fullUrl = AttachmentHelper.resolveUrl(urlTrimmed);
      if (fullUrl.contains('/api/v1/files/') &&
          !fullUrl.contains('download=')) {
        fullUrl = fullUrl.contains('?')
            ? '$fullUrl&download=true'
            : '$fullUrl?download=true';
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 45),
        ),
      );

      final response = await dio.get<List<int>>(
        fullUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null || response.data!.isEmpty) {
        return const DownloadResult(
          success: false,
          errorMessage: 'Server returned empty file content',
        );
      }

      // Try reading filename from Content-Disposition header
      String? headerFileName;
      final disposition = response.headers.value('content-disposition');
      if (disposition != null) {
        final match = RegExp(
          r'filename\*?=(?:UTF-8'
          ')?"?([^";]+)"?',
        ).firstMatch(disposition);
        if (match != null && match.group(1) != null) {
          headerFileName = Uri.decodeComponent(match.group(1)!);
        }
      }

      String finalName =
          preferredFileName ??
          headerFileName ??
          Uri.parse(fullUrl).pathSegments.lastOrNull ??
          'file_${DateTime.now().millisecondsSinceEpoch}';

      if (!finalName.contains('.')) {
        final contentType = response.headers.value('content-type') ?? '';
        finalName += guessExtension(contentType, '.bin');
      }

      final destination = _resolveUniqueFile(
        targetDir,
        sanitizeFileName(finalName),
      );
      await destination.writeAsBytes(response.data!);

      return DownloadResult(
        success: true,
        filePath: destination.path,
        fileName: destination.uri.pathSegments.last,
      );
    } catch (e) {
      return DownloadResult(success: false, errorMessage: e.toString());
    }
  }

  /// Downloads file and provides integrated UI feedback via ScaffoldMessenger.
  static Future<bool> downloadAndNotify(
    BuildContext context, {
    required String rawUrl,
    String? preferredFileName,
    String? localFilePath,
  }) async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc.translate('file_downloading'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    final res = await downloadOrSave(
      rawUrl: rawUrl,
      preferredFileName: preferredFileName,
      localFilePath: localFilePath,
    );

    if (!context.mounted) return res.success;

    messenger.hideCurrentSnackBar();

    if (res.success && res.fileName != null) {
      final savedText = loc.translate('file_saved_to_downloads');
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: LiquidTheme.success,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$savedText: ${res.fileName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: loc.translate('open_file'),
            textColor: Colors.white,
            onPressed: () {
              if (res.filePath != null) {
                _tryOpenFile(res.filePath!);
              }
            },
          ),
        ),
      );
      return true;
    } else {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: LiquidTheme.danger,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${loc.translate('file_download_error')}: ${res.errorMessage ?? 'Unknown error'}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
      return false;
    }
  }

  static void _tryOpenFile(String path) async {
    try {
      final uri = Uri.file(path);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  /// Avoids overwriting existing files by appending a numeric counter: file (1).ext
  static File _resolveUniqueFile(Directory dir, String fileName) {
    File candidate = File('${dir.path}/$fileName');
    if (!candidate.existsSync()) {
      return candidate;
    }

    final dotIndex = fileName.lastIndexOf('.');
    final baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
    final ext = dotIndex > 0 ? fileName.substring(dotIndex) : '';

    int counter = 1;
    while (candidate.existsSync()) {
      candidate = File('${dir.path}/$baseName ($counter)$ext');
      counter++;
    }
    return candidate;
  }
}
